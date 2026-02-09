# Announcements Page - Admin Portal

## Overview
For the admin portal, make the announcements page which will open when the user clicks on announcements from the settings. The page will be the same as moderator queue, with the following changes:

- The heading text will be **Announcements** instead of the Moderator Queue
- There will be no sections like Posts Comments users - this whole option tab will not be there
- There will be just a single scrollable page with 3 sections: **PINNED ANNOUNCEMENTS**, **PENDING APPROVAL**, **HISTORY** (instead of New Queue and History)
- There will be 1 post in each section

## Post Card Specifications (General)

The Post cards will be just like how the post cards are in the feed.

**Post card dimensions:**
- width: 360px
- height: 482px
- angle: 0 deg
- opacity: 1
- border-radius: 16px
- border-width: 1.51px
- padding-top: -0px
- padding-left: 0px

---

## Section 1: PINNED ANNOUNCEMENTS

**For the post under the section PINNED ANNOUNCEMENTS:**

**First post specifications:**
- Profile picture will be **MO**
- Profile picture border:
  - `border: 3px solid;`
  - `border-image-source: linear-gradient(180deg, #FF0F7B 0%, #F89B29 100%);`
- Username will be **@Moderator**
- Timestamp will be **2 hr ago**
- Badge under the username (like how admin has in the settings page): `assets/Moderator-icons/settings-icons/Moderator-badge.svg`
- Upvote and downvote container box will be the exact same as used in the feed but with the following borders:
  - `border-top: 0.76px solid;`
  - `border-image-source: linear-gradient(180deg, #FF0F7B 0%, #F89B29 100%);`
- Post card border:
  - `border: 1.51px solid;`
  - `border-image-source: linear-gradient(180deg, rgba(255, 15, 123, 0.5) 0%, rgba(248, 155, 41, 0.5) 100%);`
- For the heading text and the body text, use any filler content of any other post for now

---

## Section 2: PENDING APPROVAL

**For the post under the section PENDING APPROVAL:**
- The same Post card designed for the first post will be used

---

## Section 3: HISTORY

**For the post under the section HISTORY:**

- Profile picture will have **AD**
- Profile picture circle's borders:
  - `border: 3px solid;`
  - `border-image-source: linear-gradient(180deg, #4F39F6 0%, #9810FA 100%);`
- Username will be **@administrator**
- Badge will be the admin badge
- Upvote and downvote container box will be the same as of the above posts but the borders of this container will be:
  - `border-top: 0.76px solid;`
  - `border-image-source: linear-gradient(180deg, #4F39F6 0%, #9810FA 100%);`
- Post card borders:
  - `border: 1.51px solid;`
  - `border-image-source: linear-gradient(180deg, rgba(79, 57, 246, 0.5) 0%, rgba(152, 16, 250, 0.5) 100%);`
- The content will be the same as of the above 2 posts
