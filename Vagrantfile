
# https://github.com/phinze/landrush
["landrush"].each do |plugin|
    unless Vagrant.has_plugin?(plugin)
        $stderr.puts "\e[33mThe #{plugin} plugin is required. Please install it with:\e[0m"
        $stderr.puts "\e[33m$ vagrant plugin install #{plugin}\e[0m"
        exit
    end
end

# https://docs.vagrantup.com.
Vagrant.configure(2) do |config|

    config.vm.define "idp" do |idp|

        idp.vm.box = "bento/centos-7.2"
        idp.vm.box_version = "2.2.9"

        idp.vm.provider "virtualbox" do |v|
            v.memory = 1024
        end

        idp.landrush.enabled = true
        idp.vm.hostname = "idp.vagrant.test"

        idp.vm.provision :shell, inline: "cp /vagrant/shared/vars.sh /etc/profile.d/vars.sh; chmod +x /etc/profile.d/vars.sh"

        idp.vm.provision :shell, path: "./shared/tools.sh"
        idp.vm.provision :shell, path: "./shared/chrony.sh"
        idp.vm.provision :shell, path: "./shared/mysql.sh"
        idp.vm.provision :shell, path: "./shared/java.sh"
        idp.vm.provision :shell, path: "./shared/jetty.sh"
        idp.vm.provision :shell, path: "./shared/idp.sh"
        idp.vm.provision :shell, path: "./shared/configure-jetty-for-idp.sh"
        idp.vm.provision :shell, path: "./shared/mysql-connector-java.sh"
        idp.vm.provision :shell, path: "./idp/configure-idp.sh"
        idp.vm.provision :shell, path: "./idp/configure-ecp.sh"

        # Generate certificate
        idp.vm.provision :shell, inline: "sh /vagrant/shared/generate_cert.sh idp"

        # Metadata exchange
        idp.vm.provision :shell, inline: "/bin/cp -f /vagrant/metadata-exchange/shared/metadata-providers.xml /opt/shibboleth-idp/conf/metadata-providers.xml"
        idp.vm.provision :shell, inline: "mkdir -p /vagrant/metadata; /bin/cp -f /opt/shibboleth-idp/metadata/idp-metadata.xml /vagrant/metadata/idp-metadata.xml"

        idp.vm.provision :shell, inline: "systemctl start idp"

    end

    config.vm.define "vo-aa" do |aa|

        aa.vm.box = "bento/centos-7.2"
        aa.vm.box_version = "2.2.9"

        aa.landrush.enabled = true
        aa.vm.hostname = "vo.vagrant.test"

        aa.vm.provision :shell, inline: "cp /vagrant/shared/vars.sh /etc/profile.d/vars.sh; chmod +x /etc/profile.d/vars.sh"

        aa.vm.provision :shell, path: "./shared/tools.sh"
        aa.vm.provision :shell, path: "./shared/chrony.sh"
        aa.vm.provision :shell, path: "./shared/mysql.sh"
        aa.vm.provision :shell, path: "./shared/java.sh"
        aa.vm.provision :shell, path: "./shared/jetty.sh"
        aa.vm.provision :shell, path: "./shared/idp.sh"
        aa.vm.provision :shell, path: "./shared/configure-jetty-for-idp.sh"
        aa.vm.provision :shell, path: "./shared/mysql-connector-java.sh"
        aa.vm.provision :shell, path: "./vo-aa/configure-aa.sh"

        # Generate certificate
        aa.vm.provision :shell, inline: "sh /vagrant/shared/generate_cert.sh vo-aa"

        # Metadata exchange
        aa.vm.provision :shell, inline: "/bin/cp -f /vagrant/metadata-exchange/shared/metadata-providers.xml /opt/shibboleth-idp/conf/metadata-providers.xml"
        aa.vm.provision :shell, inline: "mkdir -p /vagrant/metadata; sh /vagrant/metadata-exchange/aa/edit-metadata.sh /opt/shibboleth-idp/metadata/idp-metadata.xml > /vagrant/metadata/vo-aa-metadata.xml"

        aa.vm.provision :shell, inline: "systemctl start idp"

    end

    config.vm.define "resource-aa" do |aa|

        aa.vm.box = "bento/centos-7.2"
        aa.vm.box_version = "2.2.9"

        aa.landrush.enabled = true
        aa.vm.hostname = "aa.vagrant.test"

        aa.vm.provision :shell, inline: "cp /vagrant/shared/vars.sh /etc/profile.d/vars.sh; chmod +x /etc/profile.d/vars.sh"

        aa.vm.provision :shell, path: "./shared/tools.sh"
        aa.vm.provision :shell, path: "./shared/chrony.sh"
        aa.vm.provision :shell, path: "./shared/mysql.sh"
        aa.vm.provision :shell, path: "./shared/java.sh"
        aa.vm.provision :shell, path: "./shared/jetty.sh"
        aa.vm.provision :shell, path: "./shared/idp.sh"
        aa.vm.provision :shell, path: "./shared/configure-jetty-for-idp.sh"
        aa.vm.provision :shell, path: "./shared/mysql-connector-java.sh"
        aa.vm.provision :shell, path: "./aa/configure-aa.sh"

        # Generate certificate
        aa.vm.provision :shell, inline: "sh /vagrant/shared/generate_cert.sh resource-aa"

        # Metadata exchange
        aa.vm.provision :shell, inline: "/bin/cp -f /vagrant/metadata-exchange/shared/metadata-providers.xml /opt/shibboleth-idp/conf/metadata-providers.xml"
        aa.vm.provision :shell, inline: "mkdir -p /vagrant/metadata; sh /vagrant/metadata-exchange/aa/edit-metadata.sh /opt/shibboleth-idp/metadata/idp-metadata.xml > /vagrant/metadata/resource-aa-metadata.xml"

        aa.vm.provision :shell, inline: "systemctl start idp"

    end

    config.vm.define "sp" do |sp|

        sp.vm.box = "bento/centos-7.2"
        sp.vm.box_version = "2.2.9"

        sp.landrush.enabled = true
        sp.vm.hostname = "sp.vagrant.test"

        sp.vm.provision :shell, path: "./shared/tools.sh"
        sp.vm.provision :shell, path: "./shared/chrony.sh"
        sp.vm.provision :shell, path: "./sp/sp.sh"
        sp.vm.provision :shell, path: "./sp/configure.sh"
        sp.vm.provision :shell, path: "./sp/test-web-dir.sh"

        # Metadata exchange
        sp.vm.provision :shell, path: "./metadata-exchange/sp/add-to-attribute-map.sh"
        sp.vm.provision :shell, path: "./metadata-exchange/sp/edit-shib-conf.py"
        sp.vm.provision :shell, inline: "systemctl start shibd; systemctl start httpd"
        sp.vm.provision :shell, inline: "curl -k \"https://$(hostname)/Shibboleth.sso/Metadata\" > /var/www/html/sp-metadata.xml"

        # Install ECP SSH
        sp.vm.provision :shell, path: "./sp/ecp-ssh/install.sh"
        sp.vm.provision :shell, path: "./sp/ecp-ssh/build.sh"
        sp.vm.provision :shell, path: "./sp/ecp-ssh/configure.sh"

    end

    config.vm.define "client", primary: true do |client|

        client.vm.box = "bento/centos-7.2"
        client.vm.box_version = "2.2.9"

        client.landrush.enabled = true

        client.vm.provider "virtualbox" do |v|
            v.gui = true
        end

        # Install desktop environment
        client.vm.provision :shell, inline: "yum groupinstall -y 'GNOME Desktop'"
        client.vm.provision :shell, inline: "systemctl set-default graphical.target"

        client.vm.provision :shell, path: "./shared/tools.sh"
        client.vm.provision :shell, path: "./shared/chrony.sh"

        # Install Shibboleth SP - required by mech_saml_ec
        client.vm.provision :shell, inline: "curl 'http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo' > /etc/yum.repos.d/shibboleth.repo"
        client.vm.provision :shell, inline: "yum install -y shibboleth"
        client.vm.provision :shell, inline: "sed -i -e 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config"

        # Install certificates
        client.vm.provision :shell, inline: "cp /vagrant/certs/idp.crt /etc/pki/ca-trust/source/anchors/idp.crt"
        client.vm.provision :shell, inline: "cp /vagrant/certs/vo-aa.crt /etc/pki/ca-trust/source/anchors/vo-aa.crt"
        client.vm.provision :shell, inline: "cp /vagrant/certs/resource-aa.crt /etc/pki/ca-trust/source/anchors/resource-aa.crt"
        client.vm.provision :shell, inline: "update-ca-trust"

        # Install ECP SSH
        client.vm.provision :shell, path: "./sp/ecp-ssh/install-moonshot.sh"
        client.vm.provision :shell, path: "./sp/ecp-ssh/install.sh"
        client.vm.provision :shell, path: "./sp/ecp-ssh/build.sh"
        client.vm.provision :shell, path: "./sp/ecp-ssh/configure-client.sh"

    end

end
