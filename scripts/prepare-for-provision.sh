#!/bin/sh
# Ideally everything should be installed via puppet but for puppet to run certain utilities need to be installed for puppet to run
sudo yum -y install ruby
sudo rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm
sudo yum -y install puppet

sudo mkdir /packages/{localrepo,servers,tools,python-packages}

sudo wget -r -nH --no-parent --reject="index.html*" https://bahmni-repo.twhosted.com/localrepo/ -P /packages
sudo wget -r -nH --no-parent --reject="index.html*" https://bahmni-repo.twhosted.com/tools/ -P /packages
sudo wget -r -nH --no-parent --reject="index.html*" https://bahmni-repo.twhosted.com/servers/ -P /packages
sudo wget -r -nH --no-parent --reject="index.html*" https://bahmni-repo.twhosted.com/python-packages/ -P /packages
sudo chmod -R 777 /packages

sudo sed -i '/^127\.0\.0\.1/ s/$/'" $HOSTNAME"'/' /etc/hosts