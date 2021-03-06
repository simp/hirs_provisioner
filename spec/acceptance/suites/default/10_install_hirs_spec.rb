require 'spec_helper_acceptance'

test_name 'hirs_provisioner class'

describe 'hirs_provisioner class' do

  #install an aca for the provisioners to talk to
  def setup_aca(aca)
    on aca, 'yum install -y mariadb-server openssl tomcat java-1.8.0 rpmdevtools coreutils initscripts chkconfig sed grep firewalld policycoreutils'
    on aca, 'yum install -y HIRS_AttestationCA'
    sleep(10)
  end

  let(:manifest) {
    <<-EOS
      include 'hirs_provisioner'
    EOS
  }

  let(:hieradata) {
    <<-EOS
---
hirs_provisioner::config::aca_fqdn: aca
    EOS
  }

  context 'set up aca' do
    it 'should start the aca server' do
      aca_host = only_host_with_role( hosts, 'aca' )
      setup_aca(aca_host)
    end
  end

  context 'with a tpm' do
    hosts_with_role(hosts, 'hirs').each do |hirs_host|

      it 'should work with no errors' do
        if hirs_host.host_hash[:roles].include?('tpm_2_0')
          package_name = 'HIRS_Provisioner_TPM_2_0'
        else hirs_host.host_hash[:roles].include?('tpm_1_2')
          package_name = 'HIRS_Provisioner_TPM_1_2'
        end
        set_hieradata_on(hirs_host, hieradata)
        apply_manifest_on(hirs_host, manifest, :catch_failures => true)
        expect( check_for_package(hirs_host, package_name)).to be true
      end

      it 'should be idempotent' do
        apply_manifest_on(hirs_host, manifest, :catch_changes => true)
      end

    end
  end
end
