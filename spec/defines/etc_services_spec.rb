require 'spec_helper'

describe 'etc_services' do
  let(:title) { 'example' }

  context 'service name too long' do
    let(:params) do
      {
        service_name: 'longlonglonglong',
        protocols: { tcp: 65_535 },
      }
    end

    it { is_expected.to compile.with_all_deps.and_raise_error(%r{etc_service: Invalid service name 'longlonglonglong'}) }
  end

  context 'service name with two consecutive \'-\'\'s' do
    let(:params) do
      {
        service_name: 'two--hiphen',
        protocols: { tcp: 65_535 },
      }
    end

    it { is_expected.to compile.with_all_deps.and_raise_error(%r{etc_service: Invalid service name 'two--hiphen'}) }
  end

  context 'service name begins with \'-\'' do
    let(:params) do
      {
        service_name: '-badstart',
        protocols: { tcp: 65_535 },
      }
    end

    it { is_expected.to compile.with_all_deps.and_raise_error(%r{etc_service: Invalid service name '-badstart'}) }
  end

  context 'service name ends with \'-\'' do
    let(:params) do
      {
        service_name: 'badend-',
        protocols: { tcp: 65_535 },
      }
    end

    it { is_expected.to compile.with_all_deps.and_raise_error(%r{etc_service: Invalid service name 'badend-'}) }
  end

  # Valid configurations
  on_supported_os.each do |os, facts|
    let(:facts) { facts }

    context "on #{os} single port" do
      let(:params) do
        {
          service_name: 'ntp',
          ensure: 'present',
          protocols: {
            udp: 123,
            tcp: 123,
          },
        }
      end

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file_line('ntp_udp').with(
          ensure: 'present',
          path: '/etc/services',
          line: 'ntp 123/udp',
          match: '^ntp\s+\d+/udp',
        )
        is_expected.to contain_file_line('ntp_tcp').with(
          ensure: 'present',
          path: '/etc/services',
          line: 'ntp 123/tcp',
          match: '^ntp\s+\d+/tcp',
        )
      }
    end

    context "on #{os} complete entry" do
      let(:params) do
        {
          service_name: 'kerberos',
          ensure: 'present',
          protocols: {
            udp: 88,
            tcp: 88,
          },
          comment: 'Kerberos v5',
          aliases: [
            'kerberos5',
            'krb5',
          ],
        }
      end

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file_line('kerberos_udp').with(
          ensure: 'present',
          path: '/etc/services',
          line: 'kerberos 88/udp kerberos5 krb5 # Kerberos v5',
          match: '^kerberos\s+\d+/udp',
        )
        is_expected.to contain_file_line('kerberos_tcp').with(
          ensure: 'present',
          path: '/etc/services',
          line: 'kerberos 88/tcp kerberos5 krb5 # Kerberos v5',
          match: '^kerberos\s+\d+/tcp',
        )
      }
    end

    context "on #{os} remove entry" do
      let(:params) do
        {
          service_name: 'kerberos',
          ensure: 'absent',
          protocols: {
            udp: 88,
            tcp: 88,
          },
          comment: 'Kerberos v5',
          aliases: [
            'kerberos5',
            'krb5',
          ],
        }
      end

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file_line('kerberos_udp').with(
          ensure: 'absent',
          path: '/etc/services',
          match: '^kerberos\s+\d+/udp',
          match_for_absence: true,
        )
        is_expected.to contain_file_line('kerberos_tcp').with(
          ensure: 'absent',
          path: '/etc/services',
          match: '^kerberos\s+\d+/tcp',
          match_for_absence: true,
        )
      }
    end

    context "on #{os} suppress syntax error" do
      let(:params) do
        {
          service_name: 'db2c_db2inst1',
          ensure: 'present',
          enforce_syntax: false,
          protocols: {
            tcp: 50_000,
          },
        }
      end

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file_line('db2c_db2inst1_tcp').with(
          ensure: 'present',
          path: '/etc/services',
          line: 'db2c_db2inst1 50000/tcp',
          match: '^db2c_db2inst1\s+\d+/tcp',
        )
      }
    end
  end
end
