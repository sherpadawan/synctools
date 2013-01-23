<?php

class Watchdog extends Task {
    protected $option;

    public function init() {}

    public function main() {
        switch ($this->option) {
            case 'list':
                system('cd ../src && drush watchdog-list');
                break;
            case 'show':
                system('cd ../src && drush watchdog-show');
                break;
        }
    }

    public function setOption($option) {
        $this->option = $option;
    }
}
