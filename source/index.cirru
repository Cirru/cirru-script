doctype

html
  head
    title "CirruScript"
    meta (:charset utf-8)
    script(:src build/vendor.min.js)
    link (:rel icon) (:href http://logo.cirru.org/cirru-32x32.png)
    @if (@ dev)
      @block
        link (:rel stylesheet) (:href source/main.css)
        script (:defer) (:src build/main.js)
      @block
        link (:rel stylesheet) (:href build/main.min.css)
        script (:defer) (:src build/main.min.js)
  body
    textarea#source (:placeholder Source)
    textarea#compiled (:placeholder Compiled)
