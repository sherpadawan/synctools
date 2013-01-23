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
    'sync.remote.servername'=>'REMOTE_SERVERNAME', 
    'sync.remote.user.login'=>'REMOTE_USER', 
    'sync.remote.db.user.name'=>'REMOTE_MYSQL_USER', 
    'sync.remote.db.user.pass'=>'REMOTE_MYSQL_PASS',
    'services.varnish' => 'VARNISH_USE',
    'services.memchached' => 'MEMCACHED_USE',
    'services.solr' => 'SOLR_USE',
  );

  protected static $instance;

  protected function __construct() {
    $this->checkCurrentEnv();
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
  public function parseProjectProperties($section=false) {
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
      $properties = $this->parseProjectProperties(true);
      $propertiesToExport = $this->computeProjectProperties($properties);
      $exportString = '';
      foreach($propertiesToExport as $varName=>$value) {
          $exportString .= 'export '.$varName.'='.addslashes($value).';';
      }
      return $exportString;
  }

  public function __toString() {
    echo $this->export();
  }

}

