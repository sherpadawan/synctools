<?php
require_once 'GNBUtilsConfig.php';

class GNBUtilsTask extends Task
{

 protected $config;
 protected $configExport;

 public function init() {
    $this->config = GNBUtilsConfig::getInstance();
    $this->configExport = $this->config->export();
 }

 public function main() {}

}
