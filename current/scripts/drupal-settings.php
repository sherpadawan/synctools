<?php

$site     = $args[1];
$f_ini      = $args[2];
$f_ini_all  = $args[3];

$ini     = parse_ini_file($f_ini,true);
$ini_all = parse_ini_file($f_ini_all,true);
$variables_all = array_diff_key($ini_all[$site],$ini[$site]);
$variables     = array_merge($ini_all[$site],$ini[$site]);
$variables     = $variables + $variables_all;

foreach($variables as $name=>$value) {
    echo "[INFO] Set $name with value ".print_r($value,1).PHP_EOL;
    variable_set($name, $value);
}
