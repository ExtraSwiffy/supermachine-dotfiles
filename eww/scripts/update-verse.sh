#!/bin/bash
set -euo pipefail

verses=(
  "John 14:6|The way, the truth, and the life"
  "Psalm 23:1|The LORD is my shepherd; I shall not want"
  "Philippians 4:13|I can do all things through Christ"
  "Proverbs 3:5|Trust in the LORD with all thine heart"
  "Romans 8:28|All things work together for good"
  "Isaiah 41:10|Fear thou not; for I am with thee"
  "Joshua 1:9|Be strong and of a good courage"
  "Matthew 6:33|Seek ye first the kingdom of God"
  "Psalm 46:10|Be still, and know that I am God"
  "John 3:16|For God so loved the world"
  "Romans 12:2|Be ye transformed by renewing your mind"
  "2 Timothy 1:7|God hath not given us the spirit of fear"
  "Psalm 119:105|Thy word is a lamp unto my feet"
  "Matthew 11:28|Come unto me, all ye that labour"
  "1 Peter 5:7|Casting all your care upon him"
  "Ephesians 2:8|By grace are ye saved through faith"
  "Hebrews 11:1|Faith is the substance of things hoped for"
  "James 1:5|If any of you lack wisdom, ask of God"
  "Psalm 37:4|Delight thyself also in the LORD"
  "Romans 10:9|Confess with thy mouth the Lord Jesus"
  "Galatians 5:22|The fruit of the Spirit is love"
  "1 John 4:19|We love him, because he first loved us"
  "Psalm 34:8|O taste and see that the LORD is good"
  "Colossians 3:23|Do it heartily, as to the Lord"
  "Micah 6:8|Do justly, love mercy, walk humbly"
  "Psalm 91:1|He that dwelleth in the secret place"
  "John 8:12|I am the light of the world"
  "Romans 5:8|Christ died for us"
  "1 Corinthians 13:13|Faith, hope, charity, these three"
  "Psalm 27:1|The LORD is my light and my salvation"
  "Isaiah 40:31|They shall mount up with wings as eagles"
  "Matthew 5:16|Let your light so shine before men"
  "John 15:5|Without me ye can do nothing"
  "Romans 8:31|If God be for us, who can be against us"
  "Ephesians 6:10|Be strong in the Lord"
  "Philippians 4:6|Be careful for nothing"
  "Colossians 3:2|Set your affection on things above"
  "1 Thessalonians 5:17|Pray without ceasing"
  "Hebrews 13:8|Jesus Christ the same yesterday, today, and for ever"
  "James 4:8|Draw nigh to God"
  "1 Peter 2:9|Ye are a chosen generation"
  "Revelation 3:20|Behold, I stand at the door, and knock"
  "Psalm 19:14|Let the words of my mouth be acceptable"
  "Psalm 55:22|Cast thy burden upon the LORD"
  "Proverbs 16:3|Commit thy works unto the LORD"
  "Isaiah 26:3|Thou wilt keep him in perfect peace"
  "Jeremiah 29:11|Thoughts of peace, and not of evil"
  "Matthew 22:37|Love the Lord thy God"
  "Luke 1:37|With God nothing shall be impossible"
  "John 10:10|I am come that they might have life"
  "Acts 16:31|Believe on the Lord Jesus Christ"
  "Romans 6:23|The gift of God is eternal life"
  "2 Corinthians 5:17|He is a new creature"
  "Galatians 2:20|Christ liveth in me"
  "Ephesians 3:20|Able to do exceeding abundantly"
  "Philippians 1:6|He which hath begun a good work"
  "Colossians 1:17|By him all things consist"
  "2 Thessalonians 3:3|The Lord is faithful"
  "1 Timothy 6:12|Fight the good fight of faith"
  "Hebrews 4:16|Come boldly unto the throne of grace"
)

choice="${verses[RANDOM % ${#verses[@]}]}"
ref="${choice%%|*}"
text="${choice#*|}"

line1=""
line2=""
line3=""

for word in $text; do
  if [ ${#line1} -lt 30 ]; then
    candidate="${line1:+$line1 }$word"
    if [ ${#candidate} -le 34 ]; then
      line1="$candidate"
      continue
    fi
  fi

  if [ ${#line2} -lt 30 ]; then
    candidate="${line2:+$line2 }$word"
    if [ ${#candidate} -le 34 ]; then
      line2="$candidate"
      continue
    fi
  fi

  line3="${line3:+$line3 }$word"
done

eww -c "$HOME/.config/eww" update \
  BIBLE_REF="$ref" \
  BIBLE_TEXT="$line1" \
  BIBLE_TEXT_2="$line2" \
  BIBLE_TEXT_3="$line3"
