In 2020, I decided to start taking content creation more seriously. This post will detail my content creation journey, which started in 2017. I will share the different things I tried, what I learned, and how much I made.

## 2017

I've been posting content online since mid 2017, when I started writing on [Medium](https://medium.com/@lachlanmiller_52885), which was *the* place to post content at the time, where I main wrote about JavaScript and Vue.js. 

Around this time I also started contributing to [Avoriaz](https://github.com/eddyerburgh/avoriaz), which later became [Vue Test Utils](https://github.com/vuejs/vue-test-utils). Since there were not many articles about how to test Vue components, I started writing some on my Medium blog. 

After a while, I had quite a few articles about Vue testing. To make it easier for people to navigate them, I put them into a small book which I named [The Vue Testing Handbook](https://lmiller1990.github.io/vue-testing-handbook/v3/). This was around mid 2018.

After this, I continued to write articles about whatever I was interested in at the time - mainly testing. I try to write about topics not many people are covering - there is a huge amount of beginner material, like "how to Hello World with XYZ framework" but not nearly enough advanced content.

## 2018

In 2018 I dicovered [Destroy All Software](https://www.destroyallsoftware.com/screencasts). I loved the speed and brevity of Gary's presentations, as well as his focus on advanced concepts. It was a breath of fresh air among the endless "Hello World" style videos on YouTube and posts on Medium. 

I also did a couple of courses on Udemy during 2018 - a React one, since I started a new job with React, and another on Redux. Udemy has some great content - you just need to search. Most of the courses I took were between $15 and $45. Some of those courses had 1000s of students - even at $10 each, those people were making tons of moeny!? I wondered if I could do that.

Around this time checked the Google Analytics for my Vue Testing Handbook. It had a ton of traffic! It got around 100k views in 2018:

![2018 views on my book](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-2018.png)
<p align="center">2018 traffic for the Vue Testing Handbook</p>

This felt awesome - people were finding my content useful! I continued to add content and improve it as I saw fit. Since I was one of the main contributors to Vue Test Utils, I had a good idea of the problems people were facing, which helped drive a lot of the content.

## 2019

2019 saw a *huge* spike in traffic to my book:

![2019 biews on my book](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-2019.png)
<p align="center">2019 traffic for the Vue Testing Handbook</p>

You can see where I broke Google Analytics in November when I bumped the dependencies. Since I had a lot of traffic, I tried putting a small advertisement in the top right hand corner of the book with [Carbon Ads](https://www.carbonads.net/). Even with 100k views / month, I only got around $15. I have no idea if this is normal or due to heavy use of adblockers by developers, but I was sure I could make more than $15 a month with this much traffic.

Around this time Evan announced plans for [Vue 3](https://github.com/vuejs/roadmap#3x). I had the idea to make a course. I didn't want it to be for beginners, there are TONS of those out there already. I decided it would be more advanced and focus on TypeScript and the Composition API (Vue 3's flagship features) and testing with Vue Test Utils, the library which I maintain. 

## 2020

I had just finished reading [The Lean Startup](http://theleanstartup.com/) and decided to follow it's philosophy. I made a little graphic and stuck it on my book with a link to my [course's website](https://vuejs-course.com). There wasn't anything there yet other than a few dot points about the course I was going to make and a form to let people submit their email. I got about 100 email registration in the first month - validation successful.

There were a few blockers on making my course:

1. Vue 3 was not released.
2. I was not good at screencasting. 
3. Vue Test Utils for Vue 3 did not exist.

Evan and the rest of the team were working on (1), so that was fine. 

## Learning to Screencast

Regarding (2) - I decided I could practice and drive traffic at the same time. I created a new 10m - 20m screencast every week for almost 6 months, and wrote an accompanying blog post. You can see the screencasts [here](https://vuejs-course.com/screencasts). To see if people would pay for my content, I made it a $20, one off payment. I really dislike the subscription model for educational content - it just seems silly. Why should I need to pay a recurring payment for a course? WTF? This is why I like Udemy - the model is good for consumers. One off payments are good.  

I posted this opinion on Twitter and got beaten to a pulp - mainly by people running subscription platforms, lol. I don't care what anyone says, I don't want a recurring fee to take a one off course, and neither does anyone else.

Anyway, some people paid for the screencasts. Since I was mainly using it to drive traffic and learn to screencast, the goal was not to turn a profit. I made the most recent few free, and the rest cost. So if you visited my site each week, you could watch all the content as it came out without paying.

Either way, some people found the content useful and paid for it. Further validation people enjoyed my content AND were willing to pay. And I was getting better at screencasting.

![Screencasts revenue](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-screencasts.png)
<p align="center">Screencast Revenue</p>

Here's a typical example of my screencasts:

<iframe src="https://player.vimeo.com/video/456395472?title=0&byline=0&portrait=0" width="640" height="360" frameborder="0" allow="autoplay; fullscreen" allowfullscreen></iframe>
<p align="center">Building a Spreadsheet Engine and UI Layer with TypeScript and Vue.js 3</p>

## Building a Brand

I also started to share my content on the [Vue.js subreddit](https://reddit.com/r/vuejs). I post there most days anyway, answering questions and helping people out - I think it's important that I do this, so I don't just seem like someone who shares their content and doesn't actually participate in the community.

![My Reddit profile](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-reddit.png)
<p align="center">Sharing content on Reddit</p>

I also started posting on [Twitter](https://twitter.com/Lachlan19900). I didn't like Twitter much before, I don't like it much now, but a lot of developers hang out there and it's a great way to build a brand. Building a brand is super important if you want to get into content creation, as I learned from [Kent C Dodds](https://kentcdodds.com/blog/intentional-career-building), who is a prolific blogger and [Gary Bernhardt](https://twitter.com/garybernhardt) who presents at conferences.

## Building Vue Test Utils for Vue.js 3

Another blocker on making my course was I needed to build the testing library I had written my book about, Vue Test Utils, for Vue 3. This was actually pretty challenging, since the Vue 3 internals are really different from Vue 2, and a lot of the hacks in [Vue Test Utils v1](https://github.com/vuejs/vue-test-utils) would not work in [Vue Test Utils v2](https://github.com/vuejs/vue-test-utils-next). I basically built the features for the library as I needed them for my course.

## Course Pre-release

I recorded about 4-5 lectures every week on Sunday for a few months. The course had 6 modules, and after I finished 4 I decided to let people buy the content. I also made the first 7 lectures free. I let people know via [Reddit](https://www.reddit.com/r/vuejs/comments/g3kszg/vuejs_3_the_composition_api_course_first_seven/) as well as emailing everyone who'd signed up (around 500 people). 

![Course Sales](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-vuejs-course.png)
<p align="center">Course Sales on my Website</p>

You can see two spikes in sales - pre-release (June) and the full release (July). Around 70 people purchased the course on my site for a total of $3000 USD in sales. This was really exciting to me - the fact people are willing to pay to listen to me talk about coding is thrilling. I still can't believe I get paid to code all day. 

I decided to self publish. I am not sure this was a bad decision, but it was a LOT of extra work. I had to build a website with authentication, set up Stripe, host my content on Vimeo ... this took a  lot of time and effort I could have spent on other things, like producing my course.

Marketing is also challenging - I don't want to spam people, so I try to keep emails to a minimum, and always include something free (like some new screencasts).

I decided to publish my course on Udemy, too, at the same price. One of the challenges I had with self publishing is purchasing power parity - while people in rich countries can easily pay $50 for a course, many people cannot afford this amount. Udemy had tiered pricing based on country, which is nice. I want my content to be available to as many people as possible.

Udemy is less profitable, but also takes WAY less overhead - no website to manage, no video hosting to mess around with.

![Course Sales on Udemy](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-udemy-1.png)
<p align="center">Course Sales on Udemy</p>

The average sale price is around $18, as opposed to $40 on my website. I think this is a good trade off, though - I only spend 1-2 hours a month answering questions on Udemy, and 0 time maintaining infrastructure.

## Making Another Course

I learned a LOT from making my first course:

- Don't spend too much time re-recording videos - they will never be perfect. Make them good, but don't obsess.
- Marketing is important. Start it early, even before you have any content.
- Personal brand is important.
- Stand out. Do something different. Unless you are the king of your niche. My niche is testing Vue.js components.

I decided to put this into action and try making a crash course for Vue.js 3. Since Vue 3 was just coming out, there were not many courses yet.

My first course took me around 4 months to complete. The second only took around 6 weeks! This was mainly due to getting better at screencasting. I made this one $30 on both my website and Udemy, to see which did better.

![Crash Course Sales on my site](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-crash.png)
<p align="center">Vue.js Crash Course Sales on My Website</p>

![Crash Course Sales on my Udemy](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-crash-udemy.png)
<p align="center">Vue.js Crash Course Sales on Udemy</p>

Udemy is king when it comes to beginner content. And yes - *13000 enrollments*.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I made a crash course about Vue.js 3. It&#39;s **FREE** for the next 3 days! 🎉 <br>You can learn basic Vue 3, Vite, Options/Composition API, basic Vuex and Vue Router. Pls leave a review if you like it, that would be helpful! <a href="https://twitter.com/hashtag/vuejs?src=hash&amp;ref_src=twsrc%5Etfw">#vuejs</a><a href="https://t.co/gPrhsTlB28">https://t.co/gPrhsTlB28</a></p>&mdash; Lachlan Miller (@Lachlan19900) <a href="https://twitter.com/Lachlan19900/status/1307138562329055238?ref_src=twsrc%5Etfw">September 19, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script> 

I made the course *free* the same day Vue.js 3 was officially released - around 12k people enrolled in the course. The tweet went viral! I could refresh the page and watch enrollments jump by 10 every time. If this had been my own site, and not Udemy, it would certainly have crashed under the load.

Lesson learned - free stuff is the best marketing.

## New Website, Writing a Book

One of the problems with making courses is it is difficult to revise them. Vue.js 3 had a few minor breaking changes in the early days, and I had to re-record several lectures. 

I had also made my website, [Vue.js Course](https://vuejs-course.com) for my original course - the domain name isn't exactly ideal - you don't go to a website called Vue.js Course expecting screencasts or blog posts. Also, I realized there is a lot more value than a couple thousand bucks in building my own brand.

I decided to create a new website, one that was more [focused on my own brand](https://lachlan-miller/me). I also got a little better at design :)

I also decided to write a book - I had a great time writing the Vue Testing Handbook. Also, books are easier to maintain and update. 

To remove the additional work of maintaining a website with a full payment system, I decided to sell my book on [Gumroad](https://gum.co/vuejs-design-patterns). It would be focused on design patterns for Vue.js.

![https://lachlan-miller.me/design-patterns-for-vuejs](https://raw.githubusercontent.com/lmiller1990/design-patterns-for-vuejs-source-code/master/banner.jpg)

In true lean spirit, I slapped together a [marketing page](https://lachlan-miller.me/design-patterns-for-vuejs) and put a banner on the Vue Testing Handbook to let people know about my upcoming book. In total I have around 1000 people on my mailing list now!

I listened to [Adam Wathan's](https://twitter.com/adamwathan) interview on Indie Hackers. One thing that stuck with me something to the meaning of "build excitement - let people know what you are doing". Every time I wrote a new chapter for my book, I'd sent it out for free to my subscribers. 

I got a TON of really useful feedback! Lesson learned again - the best marketing is free content. I also used Twitter to marketing my new blog posts and book. Some people even asked how I was going with the book, and when it would be released! It felt great, but also a bit scary!

It took me two months to write the book. I also started a [YouTube channel](https://www.youtube.com/c/LachlanMiller) in parallel. Initially I had the idea to sell some screencasts as part of the package, like [Michael Thiessen](https://michaelnthiessen.com/clean-components) in his course, Clean Components, which is known to be a great product. 

I ended up just posting all the screencasts I made for free on [YouTube](https://www.youtube.com/c/LachlanMiller), and dropped a link to my upcoming book in the description. 

The reason for this was two-fold: free content is good marketing, and building an audience on YouTube might be useful eventually. I got around 500 subscribers in 3 months, which is really exciting. Most of my subscribers came from sharing my videos on Reddit or sharing them with my emailing list when sending out free chapters from my book.

I am getting better at screencasting. I am learning to speak clearly, and type while I explaining things. Here's one of my more recently screencasts:

<iframe width="560" height="315" src="https://www.youtube.com/embed/vzR00-I3YSE" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Launching my Book

I really want to make my book available to as many people as possible, so I implemented purchasing power parity on my marketing page. You get an appropriate price based on your location using [this API](https://purchasing-power-parity.com/).

![Purchasing Power Parity](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-ppp.png)
<p align="center">Purchasing power parity</p>

Of course this is able to be spoofed - luckily most people are honest, and the base price ($30) is reasonable. I also sent out a $5 discount for all the people in my emailing list.

I sold 68 copies of my book in the first few days!

![Book sales](https://raw.githubusercontent.com/lmiller1990/electic/master/screenshots/content-ss-gumroad.png)
<p align="center">Book sales</p>

Experience and research tells me most of the sales are in the first few weeks - I don't expect this number to increase much more. I'm still really happy with the result - I wrote my first book, and made around $1400!

I paid a designer on Behance around $150 to get a really cool cover made. I love it. The bird is a Kookabarra - a native Australian bird (I am from Australia).

![Book cover](https://raw.githubusercontent.com/lmiller1990/design-pattenrns-for-vuejs/master/assets/covers/Vue.js_cover.png)
<p align="center">Cover for Design Patterns for Vue.js</p>

## Stats and Total Profit

My two goals of content creation were building a stronger personal brand and making some side income.

I accumulated around 620 Twitter follows over 11 months, and  510 YouTube subscribers over 3 months. YouTube is WAY more enjoyable for me, and seems like it's going better, so I intend to keep making content.

As for profits:

- Vue.js: The Composition API ($1577 Udemy, $2950 Personal Website) = $4527
- Vue.js Crash Course ($1393 Udemy, $442 Personal Website) = $1835
- Design Patterns for Vue.js ($1439 Gumroad)

Total: ~$7800.

Of course there are expenses. 

- Vimeo plus account: $110 / year
- Hosting (Digital Ocean) around $10 a month: $100 / year
- Design work for book cover: $150 
- A LOT OF TIME. Probably a 400 hours on content creation alone.

Total: ~$400

Considering how much time I invested in creating my content, I'd estimate my hourly wage at around $15. I learned a huge amount and had a lot of fun - it was definitely worth it! I intend to continue exploring content creation opportunities in the future, mainly focusing on Udemy and YouTube.

I'm really proud of how far I came this year. That said, my content creation journey really started in 2017 with my blog and the Vue Testing Handbook - it's unlikely I could have seen this success starting from scratch this year.

## Conclusion and Final Thoughts

I love making educational content - both video and written. I was also able to use this to build my personal brand, and make a bit of extra money on the side during 2020. I hope to continue building my brand, and hopefully earning some money on the side moving into 2021.

## Social and Content Links:

- My book, [Design Patterns for Vue.js](https://lachlan-miller.me/design-patterns-for-vuejs). 
- [My Udemy profile](https://www.udemy.com/user/lachlan-miller-4/).
- My [YouTube channel](https://www.youtube.com/c/LachlanMiller).
- [Twitter](https://twitter.com/Lachlan19900).
