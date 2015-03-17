doctype

html
  head
    title "CirruScript"
    meta (:charset utf-8)
    link (:rel icon) (:href http://logo.cirru.org/cirru-32x32.png)
    script (:defer)
      :src (@ main)
  body
    textarea#source (:placeholder Source)
    textarea#compiled (:placeholder Compiled)
