backend defaultbackend{
    .host = "127.0.0.1";
    .port = "81";
    .connect_timeout = 6000s;
    .first_byte_timeout = 6000s;
    .between_bytes_timeout = 6000s;
}

## List of IPs allowed to issue purge request by Ctrl-F5
#acl purge {
#    "127.0.0.1";
#}
#
## List of IPs allowed to access the admin interface
#acl admin {
#    "127.0.0.1";
#}

#
# Custom sub used to define the request conditions that make it not cacheable.
# Should be called from the vcl_recv and vcl_fetch subroutines.
#
sub common_pass {
    # Only GET and HEAD can be cached, so pass everything else directly
    # to the backend.
    if (req.request != "GET" && req.request != "HEAD") {
        return (pass);
    }

    # Never cache the load-balancer page needed to enable/disable the myfronts
    if  (req.http.host == "lbcheck") {
        return (pass);
    }

    # Do not check in the cache for AJAX requests, checkout and cart pages, etc...
    if (req.url ~ "^/(index.php/)?(admin|sales|wishlist|review|checkout|customer|api|newsletter)/") {
        return (pass);
    }
}

#
# vcl_recv is called when a client request is received by Varnish
#
sub vcl_recv {
    
    # The admin interface is only allowed to the IP belonging to the 
    # access_admin interface.
    # But beware about the pattern "/admin" which is also tested in the
    # whole expression. It might filter some unwanted URL.
    # e.g.  FQDN/.../adminhtml/.../
    #if (req.url ~ "/admin" && !client.ip ~ admin) {
    #    error 403 "Forbidden";
    #}

    # Our application does not manage other methods than HEAD, GET and POST
    # Warning : if you use REST webservices, add DELETE and PUT to this list
    if (req.request != "GET" &&
        req.request != "HEAD" &&
        req.request != "POST" ) {
        
        error 405 "Method not allowed.";
    }

    # By default everything goes to myfrontal backend
    set req.backend = defaultbackend;
    
    # Update the X-Forwarded-For header by adding client IP address to it
    if (req.http.x-forwarded-for) {
        set req.http.X-Forwarded-For = req.http.X-Forwarded-For ", " client.ip;
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }
    
    # Call the common conditions to avoid caching request and response
    # based on request parameters 
    call common_pass;

    # The grace period allow to serve cached entry after expiration while 
    # a new version is being fetched from the backend
    set req.grace = 30s;

    # Each cache entry on Varnish is based on a key (provided by vcl_hash)
    # AND the Vary header. This header, sent by the server, define on which
    # client header the cache entry must vary. And for each different value of
    # the specified client header, a new cache entry on the same key will be created.
    # 
    # In case of compression, the mod_deflate on the Apache backend will add 
    # "Vary: Accept-Encoding", as some HTTP client does not support the compression
    # and some support only gzip, and some gzip and deflate. The last ones are the
    # majority but they do not advertise "gzip" and "deflate" in the same order. So to avoid
    # storing a different cache for "gzip,deflate" and "deflate,gzip", we turn the
    # accept-encoding into just "gzip".
    # We do not take into account "deflate" only browsers, as they have only a theorical
    # existence ;) Worst case: they will receive the uncompressed format.
    # 
    # So at the end we would have only 2 versions for the same cache entry:
    #     - gziped
    #     - uncompressed
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "gzip") {
          set req.http.Accept-Encoding = "gzip";
        } else {
            remove req.http.Accept-Encoding;
        }
    }

    # Accept pages purge from authorized browsers' CTRl+F5
    #if (req.http.Cache-Control ~ "no-cache" && client.ip ~ purge) {
    if (req.http.Cache-Control ~ "no-cache") {
        purge("req.url == " req.url);
    }

    # by default for all the rest, we try to serve from the cache
    return (lookup);
}

#
# vcl_fetch is executed when the response come back from the backend
#
sub vcl_fetch {

    # Call the common conditions to avoid caching request and response
    # based on request parameters 
    call common_pass;

    set beresp.grace = 30s;

    # Do not cache 302 temporary redirect and 50x errors
    if (beresp.status == 302 || beresp.status >= 500) {
        return (pass);
    }

    # Define cache time depending on type, URL or status code
    #if (beresp.status == 301 || (beresp.status >=400 &&  beresp.status < 500)) {
        # Permanent redirections and client error cached for a short time
    #    set beresp.ttl = 120s;
    #} elsif (req.url ~ "\.(gif|jpg|jpeg|bmp|png|tiff|tif|ico|img|tga|wmf)$") {
    #    set beresp.ttl = 1d;
    #} elsif (req.url ~ "/skin/") {
    #    set beresp.ttl = 2h;
    #} else {
    #    # Default for all other ressources, included pages.
    #    set beresp.ttl = 2400s;
    #}

    unset beresp.http.Set-Cookie;
    return (deliver);
}

#
# vcl_deliver is called when sending the response to the client.
# Some headers are added to help debug
#
sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    }
    else {
        set resp.http.X-Cache = "MISS";
    }
    # Set myfrontal ID
    set resp.http.X-Front = "defaultbackend";

    return (deliver);
}

sub vcl_error {
    set obj.http.Content-Type = "text/html; charset=utf-8";
    synthetic {"
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>"} obj.status " " obj.response {"</title>
  </head>
  <body>
    <h1>Error "} obj.status " " obj.response {"</h1>
    <p>"} obj.response {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} req.xid {"</p>
    <hr>
    <address>
       <a href="http://www.varnish-cache.org/">Varnish cache server</a>
    </address>
  </body>
</html>
"};
    return (deliver);
}

