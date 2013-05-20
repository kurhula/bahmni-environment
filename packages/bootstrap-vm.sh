#createrepo is not present by default. Install it.
yum install createrepo

# disable yum cache
sed -i 's/keepcache=1/keepcache=0/g' /etc/yum.conf

# disable other repos
sh disable-online-repo.sh

cp /packages/local.repo /etc/yum.repos.d/
createrepo --update /packages/localrepo
touch /etc/yum.repos.d/local.repo

yum install puppet git
# git clone https://github.com/Bhamni/bahmni-environment.git