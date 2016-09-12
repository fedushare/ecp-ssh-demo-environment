# FeduShare demo environment

This provisions three virtual machines to demonstrate a deployment of a Shibboleth ECP enabled SSH server.

* Primary IdP - User's home campus IdP
   * Configured for ECP

* SP - Resource accessible by users at other organizations
   * Runs ECP enabled SSH server
   * Uses Shibboleth attribute query to get local username from attribute authority

* Attribute authority - Run by resource provider
   * Stores mapping of a user's EPPN on the primary IdP to their local username on the resource/SP machine

* Client - User's machine
   * Uses Moonshot Identity Selector to manage credentials

## Instructions:

1. Install required software.
   1. Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/).
   2. Install [landrush](https://github.com/phinze/landrush) Vagrant plugin.
      ```
      vagrant plugin install landrush
      ```

2. Provision VMs for Shibboleth identity provider, attribute authority, and service provider.
   1. Create Shibboleth VMs.
      ```
      vagrant up idp aa sp
      ```
   2. Force IdP and AA to reload SP metadata.
      ```
      sh ./scripts/reload-metadata.sh
      ```
   3. Open https://sp.vagrant.test/protected in a browser.
      * Login with a username and password listed in [idp/identities.sql](/idp/identities.sql).
      * Look in the Apache environment section to see attributes released by the IdP and attribute authority.

3. Provision client machine with GUI.
   1. Create client VM. This takes a while as it installs the GNOME desktop environment.
      ```
      vagrant up client
      ```
   2. Restart client VM. After restarting, the client VM will be in a graphical environment.
      ```
      vagrant reload client
      ```
   3. In the client VM's VirtualBox GUI, accept the CentOS license and finish the initial configuration.
      If prompted for credentials, the username and password are both 'vagrant'.

4. Configure Moonshot identity.
   1. In the client VM's VirtualBox GUI, run `moonshot` in a terminal to open the
      [Moonshot Identity Selector](https://wiki.moonshot.ja.net/display/Moonshot/User+Guide) by running `moonshot`
   2. Add an identity by following the instructions in the
      [user guide](https://wiki.moonshot.ja.net/display/Moonshot/User+Guide).
      * The username and password should match one of the identities listed in
        [idp/identities.sql](/idp/identities.sql).
      * In the issuer field, enter the location of the demo IdP's ECP single sign on service:
        `https://idp.vagrant.test/idp/profile/SAML2/SOAP/ECP`.

5. Login to SP with SSH and `mech_saml_ec`.
   1. Connect to SP VM and start the ECP sshd process.
      ```
      vagrant ssh sp
      sudo su
      systemctl start ecp-sshd
      ```

      To run the server manually with full debugging output, run
      ```
      LD_LIBRARY_PATH=/opt/shibboleth/lib64 ./moonshot-ssh/sbin/sshd -p 10022 -ddd
      ```
      A shortcut script for this is at `/vagrant/scripts/run_sshd`.

   2. SSH from client VM to SP VM. In order to use the Moonshot Identity Selector, this must be run in the client
      VM's VirtualBox GUI.
      ```
      vagrant ssh sp
      cd /home/vagrant
      ./moonshot-ssh/bin/ssh -p 10022 -vvv -l "" sp.vagrant.test
      ```

      A shortcut script for this is at `/vagrant/scripts/run_ssh`

      * The Moonshot Identity Selector should open and [prompt for an
        identity](https://wiki.moonshot.ja.net/display/Moonshot/User+Guide#UserGuide-Addingamapping).
      * You should be now be logged in as a different user. The mappings from IdP username stored in `~/.gss_eap_id`
        to SP VM local username can be found in [aa/accounts.sql](/aa/accounts.sql).

## mech_saml_ec development:

To use this environment for developing [mech_saml_ec](https://github.com/fedushare/mech_saml_ec):

1. Clone the mech_saml_ec repository.
   ```
   git clone https://github.com/fedushare/mech_saml_ec.git
   ```

2. Add a [synced folder](https://www.vagrantup.com/docs/synced-folders/virtualbox.html) to Vagrantfile to mount the
   mech_saml_ec directory on the SP and client VMs.
   ```ruby
   config.vm.define "sp" do |sp|
      ...
      sp.vm.synced_folder "/path/to/cloned/mech_saml_ec", "/home/vagrant/mech_saml_ec"
      ...
   end

   config.vm.define "client" do |sp|
      ...
      sp.vm.synced_folder "/path/to/cloned/mech_saml_ec", "/home/vagrant/mech_saml_ec"
      ...
   end
   ```

3. Build mech_saml_ec on each VM.
   ```
   vagrant ssh sp
   sh /vagrant/sp/ecp-ssh/build.sh
   ```

   ```
   vagrant ssh client
   sh /vagrant/sp/ecp-ssh/build.sh
   ```

To run without Moonshot Identity Selector:

1. Connect to client VM.
   ```
   vagrant ssh client
   ```

2. Remove identity selector.
   ```
   yum remove moonshot-ui moonshot-ui-devel
   ```

3. Set IdP environment variable.
   ```
   export SAML_EC_IDP="https://idp.vagrant.test/idp/profile/SAML2/SOAP/ECP"
   ```

## Troubleshooting

* Server DNS address could not be found.
   * Restart [landrush](https://github.com/phinze/landrush) daemon. `vagrant landrush restart`.
   * Flush DNS cache [(OSX instructions)](https://support.apple.com/en-af/HT202516).
