<?php
/**
 *@TODO
 * add services usage configuration (memcached, varnish)
 * 
 */

class GNBUtilsConfig
{
  const ENV_VARIABLE_NAME='ENV';

  protected $env;

  protected $defaultEnvs = array('DEV', 'INTEG', 'REMOTETEST', 'STAGE', 'PROD', 'TEST');

  protected $exportMap = array(
    'project.user' => 'PROJECT_USER',
    'project.sites'=>'SITES', 
    'project.sites.dbs'=>'SITES_DBS', 
    'project.envs'=>'ENVS', 
    'project.name'=>'PROJECT_NAME', 
    'project.mailinglist' => 'PROJECT_MAILINGLIST',
    'project.rootpath'=>'PROJECT_ROOT', 
    'project.rootpath.conf'=>'PROJECT_CONF', 
    'project.rootpath.src'=>'PROJECT_SRC', 
    'project.rootpath.scripts'=>'SCRIPTS_DIR', 
    'db.root.pass'=>'LOCAL_MYSQL_ROOT_PASS', 
    'db.user.name'=>'LOCAL_MYSQL_USER', 
    'db.user.pass'=>'LOCAL_MYSQL_PASS',
    'sync.remote'=>'REMOTE', 
    'sync.remote.source'=>'REMOTE_ENV', 
    'sync.remote.servername'=>'REMOTE_SERVERNAME', 
    'sync.remote.user.login' => 'REMOTE_USER',
    'sync.remote.db.user.name' => 'REMOTE_MYSQL_USER',
    'sync.remote.db.user.pass' => 'REMOTE_MYSQL_PASS',
    'services.varnish' => 'VARNISH_USE',
    'services.memchached' => 'MEMCACHED_USE',
    'services.solr' => 'SOLR_USE',
  );

  protected $properties;

  protected static $instance;

  protected function __construct() {
    try {
      $this->checkCurrentEnv();
    } catch(Exception $e) {
      echo $e->getMessage();
      exit(1);
    }
    $this->getProjectProperties();
  }


  /**
   * @return 
   *  GNBUtilsConfig instance
   */
  public static function getInstance() {
    if (empty(self::$instance)) {
      $c = __CLASS__;
      self::$instance = new $c;
    }
    return self::$instance;
  }

  public function getProjectProperties($recursive=true) {
      if (empty($this->properties)) {
          $this->properties = $this->loadProjectProperties($recursive);
      }
      return $this->properties;
  }

  /**
   * Log message function.
   *   display the message
   *   throw an Exception in case of ERROR
   * @params string $message
   * @params string $level INFO, WARNING, ERROR 
   */
  protected function log($message, $level='INFO') {
      $message = '['.$level.'] '.$message; 
      if ($level === 'ERROR') {
        throw new Exception($message);
      } 
      echo $message.PHP_EOL;
  }

  /**
   * Checks the current ENV var value
   * Throws Exception on error
   */
  public function checkCurrentEnv() {
    $currentEnv = $this->getCurrentEnv();
    if (!in_array($currentEnv, $this->defaultEnvs)) {
      $this->log( 'ENV must be set to a value within ('.implode(', ', $this->defaultEnvs).')'."\n" ,'ERROR');
    }
  }

  /**
   * Retrieve the current ENV var value
   */
  protected function getCurrentEnv() {
    if (empty($this->env)) {
      $this->env = shell_exec('echo -n $'.self::ENV_VARIABLE_NAME);
    }
    return $this->env;
  }

  /**
   * Parse the project.properties file
   * @params boolean $section 
   * @return array of properties
   */
  public function loadProjectProperties($section=false) {
      $dir = __DIR__;
      $properties = parse_ini_file($dir.'/../project.properties', $section);
      if (empty($properties)) {
        $this->log('Empty project.properties', 'ERROR');
      }
      return $properties; 
  }

  /**
   * Computes an array of properties. inheritance is applied ALL<-ENV
   * @param array properties
   * @return array
   */
  public function computeProjectProperties($properties) {
    $envProperties = array();
    if (!empty($properties[$this->env])) {
      $envProperties = $properties[$this->env];
    }
    $propertiesAll      = array_diff_key($properties['ALL'], $envProperties);
    $propertiesComputed = array_merge($properties['ALL'], $envProperties);
    $propertiesComputed = $propertiesComputed + $propertiesAll;
    $propertiesComputed = $propertiesComputed + $properties['PROJECT'];

    //implements flexible way for sync from remote.
    //sync.remote.source is defined then coonnection settings are retrieved from it
    if ( !empty($envProperties['sync.remote']) && !empty($envProperties['sync.remote.source'])) {
      $remoteEnvName = $envProperties['sync.remote.source'];
      if ( in_array($remoteEnvName, $this->defaultEnvs) ) {
        $propertiesComputed = array_merge( $propertiesComputed, $this->getRemoteEnvConnectionSettings($remoteEnvName));
      }
    }
    $propertiesToExport = array();
    foreach($this->exportMap as $key=>$value) {
      if( !isset($propertiesComputed[$key]) || $propertiesComputed[$key] === '' ) {
        $propertiesToExport[$value] = ''; 
      }
      else {
        $propertiesToExport[$value] = $propertiesComputed[$key];
      }
    }
    return $propertiesToExport;
  }
  
  /**
   * Return all envariable to export 
   * @return string of bash command
   */
  public function export() {
      $propertiesToExport = $this->computeProjectProperties($this->properties);
      $exportString = '';
      foreach($propertiesToExport as $varName=>$value) {
          $exportString .= 'export '.$varName.'='.addslashes($value).';';
      }
      return $exportString;
  }

  public function __toString() {
    echo $this->export();
  }

  /**
   *
   */
  public function getRemoteEnvConnectionSettings($envName) {
    $settings = array();
    if (empty($this->properties[$envName]['system.user.login'])) {
      $this->log('Missing required '.$envName.'project.properties settings (system.user.login)', 'ERROR');
    }
    if (empty($this->properties[$envName]['system.servername'])) {
      $this->log('Missing required '.$envName.' project.properties settings (system.user.login)', 'ERROR');
    }
    if (empty($this->properties[$envName]['db.user.pass'])) {
      $this->log('Missing required '.$envName.' project.properties settings (db.user.pass)', 'ERROR');
    }
    if (empty($this->properties[$envName]['db.user.name'])) {
      $this->log('Missing required '.$envName.' project.properties settings (db.user.name)', 'ERROR');
    }
    $settings['sync.remote.user.login'] = $this->properties[$envName]['system.user.login'];
    $settings['sync.remote.servername'] = $this->properties[$envName]['system.servername'];
    $settings['sync.remote.db.user.pass'] = $this->properties[$envName]['db.user.pass'];
    $settings['sync.remote.db.user.name'] = $this->properties[$envName]['db.user.name'];
    return $settings;
  }


}

