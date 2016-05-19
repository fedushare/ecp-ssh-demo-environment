# FeduShare demo environment

This provisions three virtual machines to demonstrate a deployment of a Shibboleth ECP enabled SSH server.

* Primary IdP - User's home campus IdP
    * Configured for ECP

* SP - Resource accessible by users at other organizations
    * Runs ECP enabled SSH server
    * Uses Shibboleth attribute query to get local username from attribute authority

* Attribute authority - Run by resource provider
    * Stores mapping of a user's EPPN on the primary IDP to their local username on the SP

## Instructions:

1. Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/).

2. Install [landrush](https://github.com/phinze/landrush) Vagrant plugins.
    ```Shell
    vagrant plugin install landrush
    ```

3. Create VMs.
    ```Shell
    vagrant up
    ```

4. Reload IDP metadata.
    ```Shell
    sh ./scripts/reload-metadata.sh
    ```

5. Open https://sp.vagrant.test/protected in a browser.
    * Login with a username and password listed in [idp/identities.sql](/idp/identities.sql).
    * Look in the Apache environment section to see attributes released by the IdP and attribute authority.

6. Open two terminal windows.
    * In one, start the ECP sshd process.
        * `vagrant ssh sp`
        * `sudo su`
        * `systemctl start ecp-sshd`

        To run the server manually with full debugging output, run
        `LD_LIBRARY_PATH=/opt/shibboleth/lib64 ./moonshot-ssh/sbin/sshd -p 10022 -ddd -r`.

    * In the other, test connecting as a user.
        * `vagrant ssh sp`
        * The username and password of a user on the primary IDP are stored in `~/.gss_eap_id`.
        * `./moonshot-ssh/bin/ssh -p 10022 -vvv -l "" $(hostname)`
        * You should be now be logged in as a different user. The mappings from username stored in `~/.gss_eap_id` to
          shell user can be found in [aa/accounts.sql](/aa/accounts.sql).

## mech_saml_ec development:

To use this environment for development of [mech_saml_ec](https://github.com/fedushare/mech_saml_ec):

1. Clone the mech_saml_ec repository.

2. Add a [synced folder](https://www.vagrantup.com/docs/synced-folders/virtualbox.html) to Vagrantfile to mount the
   mech_saml_ec directory on the SP VM.
    ```ruby
    config.vm.define "sp" do |sp|
        ...
        sp.vm.synced_folder "/path/to/mech_saml_ec", "/mech_saml_ec"
        ...
    end
    ```

3. Change the path to mech_saml_ec in `sp/ecp-ssh/build.sh`.
    ```Shell
    MECH_SAML_DIR=/mech_saml_ec
    ```

4. Build mech_saml_ec.
    ```Shell
    sh /vagrant/sp/ecp-ssh/build.sh
    ```
