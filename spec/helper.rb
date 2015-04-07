require 'pathname'
begin
  require 'bacon'
rescue LoadError
  require 'rubygems'
  require 'bacon'
end

begin
  if (local_path = Pathname.new(__FILE__).dirname.join('..', 'lib', 'bougy_bot.rb')).file?
    require local_path
  else
    require 'bougy_bot'
  end
rescue LoadError
  require 'rubygems'
  require 'bougy_bot'
end

Bacon.summary_on_exit

describe 'Spec Helper' do
  it 'Should bring our library namespace in' do
    BougyBot.should == BougyBot
  end
end
