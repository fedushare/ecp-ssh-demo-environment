
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

        idp.vm.box = "boxcutter/centos71"

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

    config.vm.define "aa" do |aa|

        aa.vm.box = "boxcutter/centos71"

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
        aa.vm.provision :shell, inline: "sh /vagrant/shared/generate_cert.sh aa"

        # Metadata exchange
        aa.vm.provision :shell, inline: "/bin/cp -f /vagrant/metadata-exchange/shared/metadata-providers.xml /opt/shibboleth-idp/conf/metadata-providers.xml"
        aa.vm.provision :shell, inline: "mkdir -p /vagrant/metadata; sh /vagrant/metadata-exchange/aa/edit-metadata.sh /opt/shibboleth-idp/metadata/idp-metadata.xml > /vagrant/metadata/aa-metadata.xml"

        aa.vm.provision :shell, inline: "systemctl start idp"

    end

    config.vm.define "sp", primary: true do |sp|

        sp.vm.box = "boxcutter/centos71"

        sp.landrush.enabled = true
        sp.vm.hostname = "sp.vagrant.test"

        sp.vm.provision :shell, path: "./shared/tools.sh"
        sp.vm.provision :shell, path: "./shared/chrony.sh"
        sp.vm.provision :shell, path: "./sp/sp.sh"
        sp.vm.provision :shell, path: "./sp/configure.sh"
        sp.vm.provision :shell, path: "./sp/test-web-dir.sh"

        # Install certificates
        sp.vm.provision :shell, inline: "cp /vagrant/certs/idp.crt /etc/pki/ca-trust/source/anchors/idp.crt"
        sp.vm.provision :shell, inline: "cp /vagrant/certs/aa.crt /etc/pki/ca-trust/source/anchors/aa.crt"
        sp.vm.provision :shell, inline: "update-ca-trust"

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

end
