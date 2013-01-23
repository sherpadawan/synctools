<?php

class Cache extends Task {
    protected $option;

    public function init() {}

    public function main() {
        switch ($this->option) {
            case 'clear':
                echo "Clearing all the caches\n";
                system('../scripts/clear-cache.sh');
                break;
            case 'all':
                echo "Running drush cc all\n";
                system('cd ../src && drush cc all');
                break;
        }
    }

    public function setOption($option) {
        $this->option = $option;
    }
}
