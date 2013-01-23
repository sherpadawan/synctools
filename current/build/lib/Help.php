<?php

class Help extends Task {
    public function init() {}

    public function main() {
        // Read the build.xml file.
        $file = simplexml_load_file('build.xml');
        foreach ($file->target as $target) {
            $name = $target['name'];
            $description = $target->description['text'];
            $numberOfTabs = round(strlen((string) $name) / 8);
            if ($numberOfTabs < 1) {
              $numberOfTabs += 2;
            }
            $display = "\t\033[1m";
            $display .= $name;
            $display .= "\033[m";
            for ($i = 0; $i < $numberOfTabs; $i++) {
                $display .= "\t";
            }
            $display .= $description;
            $display .= "\n";
            echo $display;
        }
    }
}
