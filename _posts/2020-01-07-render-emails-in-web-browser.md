---
layout: post
title: 💌 Render emails from ActionMailer in HTML views
description: A walkthrough on how to dig inside rails base code.
thumb_image: render-emails-in-views-in-web-browser-thumb.jpg
tags: [rails]
---

**tldr**: You can scroll to the [Solution](#solution) section if you want the final code.

Sometimes you need to let your users preview some emails, like
transactional emails customized by them with some content or style.

I have to built a preview system like this for
[Superdocu](https://www.superdocu.com/?utm_source=skelz0r&utm_medium=blog&utm_campaign=1), and I thought it'll
be an easy task thanks to
[ActionMailer::Preview](https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails).
But it wasn't : there's no officiel documentation for embedding this feature in
production.

There's
[plenty](https://stackoverflow.com/questions/27453578/rails-4-email-preview-in-production/39399116)
[of](https://stackoverflow.com/questions/28614994/rails-email-preview-for-users-in-production)
[topics](https://stackoverflow.com/questions/7165064/how-do-i-preview-emails-in-rails)
[on](https://stackoverflow.com/questions/39187800/previewing-mailers-on-non-development-tiers)
[StackOverflow](https://stackoverflow.com/questions/44911339/mailer-preview-not-working),
but none of them explains how to extract or use the rails preview system used in
development.

There's also a few gems ([Maily](https://github.com/markets/maily) or [Rails Email Preview](https://github.com/glebm/rails_email_preview) for example),
but they use rails engines, which is not really end-user friendly.

Finally, the default preview system used by `ActionMailer::Preview` is not a
valid solution, because it can't be easily integrated ou customized in the
application.

I tried to call the mailer directly and render its html part (decoded) like
this:

**Controller**
{% highlight ruby %}
@preview = UserMailer.signup(user).html_part.decoded
{% endhighlight %}

**View**
{% highlight erb %}
<%= @preview.html_safe %>
{% endhighlight %}

But it didn't work, because of inline attachments which aren't correctly
decoded 😕

So I have to understand how rails emails previewing system works and how to use it in order to
implement my previewing system, and avoid to rewrite in html my mailers' views
(it uses the [mjml](https://mjml.io/)
framework, so mjml templates and not html templates).

## Investigating how to extract the email previewing system

I started by investigating rails logs to find the name of the controller which
handles the preview action : `Rails::MailersController`

I searched in the [rails basecode](https://github.com/rails/rails), with the
controller named, which can be find
[here](https://github.com/rails/rails/blob/master/railties/lib/rails/mailers_controller.rb),
in the railties folder.

It has multiple actions, but it's the `preview` action which is interesting for us :
it handles both the entire page and the iframe part.

Here is the `preview` action code 👇

{% highlight ruby %}
def preview
  if params[:path] == @preview.preview_name
    @page_title = "Mailer Previews for #{@preview.preview_name}"
    render action: "mailer"
  else
    @email_action = File.basename(params[:path])

    if @preview.email_exists?(@email_action)
      @page_title = "Mailer Preview for #{@preview.preview_name}##{@email_action}"
      @email = @preview.call(@email_action, params)

      if params[:part]
        part_type = Mime::Type.lookup(params[:part])

        if part = find_part(part_type)
          response.content_type = part_type
          render plain: part.respond_to?(:decoded) ? part.decoded : part
        else
          raise AbstractController::ActionNotFound, "Email part '#{part_type}' not found in #{@preview.name}##{@email_action}"
        end
      else
        @part = find_preferred_part(request.format, Mime[:html], Mime[:text])
        render action: "email", layout: false, formats: [:html]
      end
    else
      raise AbstractController::ActionNotFound, "Email '#{@email_action}' not found in #{@preview.name}"
    end
  end
end
{% endhighlight %}

The first condition handles when there's no action in the path. For example if you have an
actionmail preview for `UserMailer`, it will renders available preview methods.

The second part (in the first else)
handles both the view with iframe and the mailer content part
inside iframe (
[the content part action is called here](https://github.com/rails/rails/blob/master/railties/lib/rails/templates/rails/mailers/email.html.erb#L125)
).

Now I have to understand how the final render works on this preview system:
there's a class which handles this magic, which is
[ActionMailer::InlinePreviewInterceptor](https://github.com/rails/rails/blob/master/actionmailer/lib/action_mailer/inline_preview_interceptor.rb).

This class replace converts image tag src attributes that use inline `cid:` style URLs
to `data:` style URLs so that they are visible when previewing an HTML email in a web browser.

In our `preview` action, this class is called here:

{% highlight ruby %}
  @email = @preview.call(@email_action, params)
{% endhighlight %}

The `call` method from `ActionMailer::Preview` class calls a private method
`inform_preview_interceptors`
(
[source](https://github.com/rails/rails/blob/master/actionmailer/lib/action_mailer/preview.rb#L137)
), which calls the
`ActionMailer::InlinePreviewInterceptor`'s `transform` method
(
[source](https://github.com/rails/rails/blob/master/actionmailer/lib/action_mailer/inline_preview_interceptor.rb#L28)
),
which does the trick on images 🪄

## Solution

Thanks to this investigation, I managed to fix the original implementation like
this:

**Controller**
{% highlight ruby %}
email = UserMailer.signup(user)
@preview = ActionMailer::InlinePreviewInterceptor.previewing_email(email).html_part.decoded
{% endhighlight %}

**View**
{% highlight erb %}
<%= @preview.html_safe %>
{% endhighlight %}

Have a nice day 🙃
