require 'spec_helper'

require 'open3'
require 'tempfile'

RSpec.describe 'validation' do
  let(:common_args) { '--verbose --trace --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    it 'allows listing' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation")
      expect(output.strip).to match %r{^test_validation}
      expect(status.exitstatus).to eq 0
    end

    it 'allows listing a present instance' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation foo")
      expect(output.strip).to match %r{^test_validation}
      expect(status.exitstatus).to eq 0
    end

    context 'when listing an absent instance' do
      it 'requires params' do
        output, status = Open3.capture2e("puppet resource #{common_args} test_validation nope")
        expect(output.strip).to match %r{Test_validation\[nope\] failed: The following mandatory attributes where not provided}
        expect(status.exitstatus).to eq 1
      end

      it 'is not satisfied with params only' do
        output, status = Open3.capture2e("puppet resource #{common_args} test_validation nope param=2")
        expect(output.strip).to match %r{Test_validation\[nope\] failed: The following mandatory attributes where not provided}
        expect(status.exitstatus).to eq 1
      end
    end

    it 'allows removing' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation foo ensure=absent param=2")
      expect(output.strip).to match %r{^test_validation}
      expect(output.strip).to match %r{Test_validation\[foo\]/ensure: undefined 'ensure' from 'present'}
      expect(status.exitstatus).to eq 0
    end

    it 'allows removing an absent instance' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation nope ensure=absent param=2")
      expect(output.strip).to match %r{^test_validation}
      expect(status.exitstatus).to eq 0
    end

    it 'validates params on delete' do
      output, status = Open3.capture2e("puppet resource #{common_args} test_validation bye ensure=absent param=not_a_number")
      expect(output.strip).to match %r{Test_validation\[bye\]: test_validation.param expect.* an Integer value, got String}
      expect(status.exitstatus).to eq 1
    end
  end

  describe 'using `puppet apply`' do
    it 'allows managing' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"test_validation{ foo: prop => 2, param => 3 }\"")
      expect(output.strip).not_to match %r{test_validation}i
      expect(output.strip).not_to match %r{warn|error}
      expect(status.exitstatus).to eq 0
    end

    it 'allows creating' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"test_validation{ new: prop => 2, param => 3 }\"")
      expect(output.strip).to match %r{Test_validation\[new\]/ensure: defined 'ensure' as 'present'}
      expect(status.exitstatus).to eq 0
    end

    it 'validates property' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"test_validation{ new: prop => not_a_number }\"")
      expect(output.strip).to match %r{Test_validation\[new\]: test_validation.prop expect.* an Integer value, got String}
      expect(status.exitstatus).to eq 1
    end

    it 'allows removing' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"test_validation{ foo: ensure => absent, param => 3 }\"")
      expect(output.strip).to match %r{Test_validation\[foo\]/ensure: undefined 'ensure' from 'present'}
      expect(status.exitstatus).to eq 0
    end

    it 'allows managing an absent instance' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"test_validation{ gone: ensure => absent, param => 3 }\"")
      expect(output.strip).not_to match %r{test_validation}i
      expect(output.strip).not_to match %r{warn|error}
      expect(status.exitstatus).to eq 0
    end

    it 'validates params' do
      output, status = Open3.capture2e("puppet apply #{common_args} -e \"test_validation{ gone: ensure => absent, param => not_a_number }\"")
      expect(output.strip).to match %r{Test_validation\[gone\]: test_validation.param expect.* an Integer value, got String}i
      expect(status.exitstatus).to eq 1
    end
  end
end