<?php
require_once 'GNBUtilsTask.php';

class SyncTask extends GNBUtilsTask {
    protected $type = NULL;

    public function main() {
        switch ($this->type) {
            case 'all':
                system($this->configExport . ' ../scripts/sync_all.sh ' . $this->site);
                break;
            case 'src':
                system($this->configExport . ' ../scripts/sync_src.sh');
                break;
            case 'db':
                system($this->configExport . ' ../scripts/sync_db.sh ' . $this->site);
                break;
            case 'files':
                system($this->configExport . ' ../scripts/sync_files.sh ' . $this->site);
                break;
        }
    }

    public function setSite($site) {
        $this->site = $site;
    }

    public function setType($type) {
        $this->type = $type;
    }

}
