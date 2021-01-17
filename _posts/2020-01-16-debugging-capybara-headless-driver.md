---
layout: post
title: 👾 Debugging Capybara in headless mode
description: How I manage to find the problem on Github Actions thanks to remote debugging
thumb_image: debugging-capybara-headless-driver/meta.jpg
tags:
  - english
  - rails
---

Github provides since [august
2019](https://github.blog/2019-08-08-github-actions-now-supports-ci-cd/) a new
way to orchestrate any workflow, based on any event : Github Actions. A lot of developers
migrates to this for their CI, because it's (almost) free and fully integrated
with github (no need to register to a new service for CI !).

The setup for a Ruby on Rails app with some features tests based on Capybara
and some javascript is quite simple with the [apparition gem](https://github.com/twalpole/apparition) (it works
out of a box, without any specific configurations).

You can find an example of a working CI configuration
[here](https://gist.github.com/skelz0r/1edd3b9aef22fde307ed2031684e14be) (this
example use some caching, rubocop and brakeman).

One day, my CI stopped working : I had some js features tests which failed ( but
not on my computer ). I was like " Damn, remote debugging headless chrome tests
seems to be pretty hard 😬".

And yes, it was not an easy process 🙄... that's why I wrote this post today.

## Finding a tool to reproduce the fail scenario

In my computer, failing tests are green, so I have to find a way to reproduce it.

I find a tool named [act](https://github.com/nektos/act), which seems
to be a great fit for my needs : it uses Docker (like Github Actions) and read
Github Actions configuration files in `.github/workflows` to reproduce the exact
behaviour of github actions.

However, I had multiple issues with it 😕
1. First, [I does not resolve tag well](https://github.com/nektos/act/issues/311), and failed on
   my second step.
2. Second, I had an issue on a [env
   variable which was not set](https://github.com/nektos/act/issues/265)
3. And the last one which led me to seek to an another solution :

{% highlight shell %}
[Rails tests/RSpec]   ❓  ::group::Installing Bundler
| Using Bundler 2.1.4 from Gemfile.lock BUNDLED WITH 2.1.4
| [command]/opt/hostedtoolcache/Ruby/2.7.2/x64/bin/gem install bundler -v 2.1.4 --no-document
| /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/yaml.rb:3: warning: It seems your ruby installation is missing psych (for YAML output).
| To eliminate this warning, please install libyaml and reinstall your ruby.
| /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require': libyaml-0.so.2: cannot open shared object file: No such file or directory - /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/x86_64-linux/psych.so (LoadError)
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/psych.rb:13:in `<top (required)>'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/yaml.rb:4:in `<top (required)>'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/core_ext/kernel_require.rb:92:in `require'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems.rb:712:in `load_yaml'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/config_file.rb:332:in `load_file'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/config_file.rb:182:in `initialize'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/gem_runner.rb:79:in `new'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/gem_runner.rb:79:in `do_configuration'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/lib/ruby/2.7.0/rubygems/gem_runner.rb:44:in `run'
|       from /opt/hostedtoolcache/Ruby/2.7.2/x64/bin/gem:21:in `<main>'
| Took   0.10 seconds
[Rails tests/RSpec]   ❓  ::endgroup::
[Rails tests/RSpec]   ❗  ::error::The process '/opt/hostedtoolcache/Ruby/2.7.2/x64/bin/gem' failed with exit code 1
[Rails tests/RSpec]   ❌  Failure - Setup ruby
{% endhighlight %}

The (painful) error:

`To eliminate this warning, please install libyaml and reinstall your ruby.`

My reaction 👇

{% asset 'no.jpg' %}

I gave up and tried something else, which I knew will be more tricky : remote debugging 👾

### Remote debugging

I found a github action that can create a tmate session on the host system :
[action-tmate](https://github.com/mxschmitt/action-tmate)

All you have to do it's to put the step just before the rspec step, push on
github, and connect to a ssh session.

When you open the action, you'll see the information to connect to this
session:

{% highlight shell %}
Created new session successfully
ssh vJg3mMskB7WnnLfYHRtCDFRpE@nyc1.tmate.io

https://tmate.io/t/vJg3mMskB7WnnLfYHRtCDFRpE
{% endhighlight %}

FYI, It will loop until you (or Github) decide to stop the container.

In my case, I had to see what's going on my headless browser.
Thanks to apparition, it's possible to [takes
screenshots](https://github.com/twalpole/apparition#taking-screenshots-with-some-extensions),
so I put this line just before one of my failing assertion:

{% highlight ruby %}
# spec/features/whatever_spec.rb
it 'does stuff', js: true do
  perform_some_actions

  save_screenshot(Rails.root.join('screenshot.png'))

  perform_assertions
end
{% endhighlight %}

All I need to do is to connect to the remote session, run the failing test
and get the screenshot (thanks to [transfer.sh](https://transfer.sh/), `scp` and
`rsync` does not work on tmate.io)

{% highlight shell %}
ssh vJg3mMskB7WnnLfYHRtCDFRpE@nyc1.tmate.io

# On the remote session
bundle exec rspec spec/features/whatever_spec.rb
curl --upload-file screenshot.png https://transfer.sh/screenshot.png
{% endhighlight %}

Here is my remote screenshot 👇
{% asset 'debugging-capybara-headless-driver/remote-screenshot.png' %}

On this test, one of my `perform_some_actions` is to toggle the content by
clicking on the element (example below, same screenshot but on my computer)

{% asset 'debugging-capybara-headless-driver/local-screenshot.png' %}

Clearly the action of toggling the content does not work on the CI.

My clicking action from my capybara test:

{% highlight ruby %}
find("#request_#{request.id}").click
{% endhighlight %}

And my actual DOM:

{% highlight erb %}
<div id="<%= dom_id(request) %>" class="card padding-small" data-controller="content-toggle" data-content-toggle-toggle-class="hidden" data-content-toggle-icon="chevron-bottom">
  <div class="block lg:flex mb-4 items-center">
    <div class="w-full text-center lg:text-left lg:w-2/3" data-action="click->content-toggle#toggle">
      Some content
    </div>
    <div class="w-full text-center lg:w-1/3 lg:text-right" data-action="click->content-toggle#toggle">
      Another content
    </div>
  </div>
</div>
{% endhighlight %}

I use [StimulusJS](https://stimulus.hotwire.dev/) to trigger some javascript
(rails way!) (and some [Tailwind CSS](https://tailwindcss.com/)).

I suspect that
Capybara tries to click on the div, but not on the 2 last divs which triggers
the actual toggle (divs with `data-action="click->content-toggle#toggle"`)

I tried to harden my clicking action by targetting the exact div like this:

{% highlight ruby %}
all("#request_#{request.id} [data-action=\"click->content-toggle#toggle\"]").first.click
{% endhighlight %}

I pushed on my debugging branch to trigger the build with my tmate action
enabled (in order to run this test exactly) and guess what : it worked 🙌🎉

## Conclusion

1. [act](https://github.com/nektos/act) seems promising, I'll definitely watch
   the evolution (be able to debug actions in local is definitely a nice to
   have!)
2. Take screenshots and upload them in order to inspect exactly what's happen on
   your remote session, transfer.sh is a great tool for this

Have a pleasant day 🙃
