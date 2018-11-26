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
        is_expected.to contain_augeas('ntp_udp').with(
          incl: '/etc/services',
          lens: 'Services.lns',
          changes: [
            'defnode node service-name[.=\'ntp\'][protocol = \'udp\'] ntp',
            'set $node/port 123',
            'set $node/protocol udp',
            'remove $node/alias',
            'remove $node/#comment',
          ],
        )
        is_expected.to contain_augeas('ntp_tcp').with(
          incl: '/etc/services',
          lens: 'Services.lns',
          changes: [
            'defnode node service-name[.=\'ntp\'][protocol = \'tcp\'] ntp',
            'set $node/port 123',
            'set $node/protocol tcp',
            'remove $node/alias',
            'remove $node/#comment',
          ],
        )
      }
    end
  end
end
