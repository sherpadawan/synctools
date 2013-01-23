#/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

cd  $PROJECT_SRC
echo "[INFO] Updating Sources ..."
svn up
if [ $? -ne 0 ];then
	read -p "Do you to force svn update (svn up --force) ? N/y" ans
	if [ "$ans" != "y" ];then
		echo "Cancelled!"
 		exit 1
	else
		svn up --force
	fi
fi

bash $SCRIPTS_DIR/fix-env.sh
