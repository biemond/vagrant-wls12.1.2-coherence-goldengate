#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe "the dirtree function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    Puppet::Parser::Functions.function("dirtree").should == "function_dirtree"
  end

  it "should raise a ParseError if the first argument is not a String or Array" do
    lambda { scope.function_dirtree([]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if the first argument is not an absolute path" do
    lambda { scope.function_dirtree(['usr/share/puppet'])}.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if the second argument is not a String" do
    lambda { scope.function_dirtree(['/usr/share/puppet', 1]) }.should( raise_error(Puppet::ParseError) )
  end

  it "should raise a ParseError if the second argument is not an absolute path" do
    lambda { scope.function_dirtree(['/usr/share/puppet', 'usr/share']) }.should( raise_error(Puppet::ParseError) )
  end

  it "should return an array of the posix directory tree" do
    result = scope.function_dirtree(['/usr/share/puppet'])
    result.should(match_array(['/usr', '/usr/share', '/usr/share/puppet']))
  end

  it "should return an array of the windows directory tree" do
    result = scope.function_dirtree(['C:\\windows\\system32\\'])
    result.should(match_array(["C:\\windows", "C:\\windows\\system32"]))
  end

  it "should return an array of all paths given an array of paths" do
    result = scope.function_dirtree([['/usr/share/puppet', '/var/lib/puppet/ssl', '/var/lib/puppet/modules']])
    result.should(match_array(['/usr', '/usr/share', '/usr/share/puppet',
                               '/var', '/var/lib', '/var/lib/puppet', '/var/lib/puppet/ssl',
                               '/var/lib/puppet/modules']))
  end

  it "should return an array of the posix directory tree without the first directory" do
    result = scope.function_dirtree(['/usr/share/puppet', '/usr'])
    result.should(match_array(['/usr/share', '/usr/share/puppet']))
  end

  it "should return an array of the windows directory tree without the first directory" do
    result = scope.function_dirtree(['C:\\windows\\system32\\drivers\\', 'C:\\windows'])
    result.should(match_array(["C:\\windows\\system32", "C:\\windows\\system32\\drivers"]))
  end

  it "should return the array without the first directory if there's a trailing slash on the exclude" do
    result = scope.function_dirtree(['/var/lib/puppet/ssl', '/var/lib/'])
    result.should(match_array(['/var/lib/puppet', '/var/lib/puppet/ssl']))
  end

  it "should return an array of all paths given an array of paths without the specified directory" do
    result = scope.function_dirtree([['/usr/share/puppet', '/var/lib/puppet/ssl', '/var/lib/puppet/modules'], '/var/lib'])
    result.should(match_array(['/usr', '/usr/share', '/usr/share/puppet',
                                '/var/lib/puppet', '/var/lib/puppet/ssl',
                                '/var/lib/puppet/modules']))
  end

end
