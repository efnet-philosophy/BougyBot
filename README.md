BougyBot
--------

  simple irc bot

## Requirements

* `rvm`: from rvm.git.io
* PostgreSQL: for the database. Other databases supported by the ruby Sequel library may work, only tested with PostgreSQL.
  

Usage
-----
clone this tree

```
% git clone https://github.com/bougyman/BougyBot
% cd BougyBot
% rvm current
```

This should return `ruby-<version>@bougy_bot`. If it does not, do not
move on until this works. You can try to 

```
% rvm use $(<.ruby-version)@$(<.ruby-gemset)
```
And it should force it to the correct gemset and/or tell you what is wrong.

#### Configuration

Copy one of the config/ files to a name of your choosing.

```
cp config/everything.json config/wonderbot.json
```

Edit config/wonderbot.json. Take a look at options.rb for what can be set (servers to connect to, etc).

#### Database
Create the database user (botuser) and database (botdb)

```
% sudo -u postgres createuser -P botuser
% sudo -u postgres createdb botdb -O botuser
```
Create the initial table structure
```
% sequel -m ./migrate postgres://botuser@127.0.0.1/botdb
```

#### Run it! (Do this in a tmux or GNUScreen)
```
% BougyBot_ENV=wonderbot ruby ./bot.rb
```
You are now in an interactive ruby shell, you should make sure you are in a detachable terminal (tmux or GNUScreen)
We must create one Quote before the bot will start.
```
[1] pry(BougyBot)> Quote.create quote: 'Boo', author: 'bougyman'
=> #<BougyBot::Quote @values={:id=>420309, :quote=>"Boo", :author=>"bougyman", :tags=>nil, :at=>2015-04-09 15:13:55 +0000, :last=>2015-04-09 15:13:55 +0000}>
[2] pry(BougyBot)> (wonder = clever).start
```
Make the quote whatever you like by whoever you like, of course.
This will seemingly do nothing. Not to worry, it is now running. Go to another tmux/screen window and follow the output of ./clever.log to see

```
% tail -F clever.log
```

#### Interactivity

If you hit Ctrl-C on the pry session `(wonder = clever).start`, you have access to the running instance.
```
[1] pry(BougyBot)> (wonder = clever).start # <<<Hit Ctrl-C>>>
Interrupt: 
from /home/bougyman/.rvm/gems/ruby-2.2.0@bougy_bot/gems/cinch-2.1.0/lib/cinch/irc.rb:221:in `join'
[2] pry(BougyBot)> bot = wonder.bot
=> #<Bot nick="WonderBot">
[3] pry(BougyBot)> bot.channels
=> [#<Channel name="#philosophy">, #<Channel name="#linuxgeneration">]
[4] pry(BougyBot)> lg = bot.channels[1]
=> #<Channel name="#linuxgeneration">
[5] pry(BougyBot)> lg.msg "Hi from interactive"
=> ["Hi from interactive"]
[6] pry(BougyBot)> 
```

#### Explore

Cinch plugin code is super easy to wrote. See examples in lib/bougy_bot/plugins/

Copyright(c) 2015 by bougyman
