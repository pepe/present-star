(use spork/test)

(start-suite "docs")
(assert-docs "../present-star")
(end-suite)
(start-suite)
(import ../present-star/init :prefix "ps/")

(assert (= "<!DOCTYPE html>\r\n<html lang=\"en\">\r\n  <head>\r\n    <title>Test presentation</title>\r\n    <meta charset=\"utf-8\">\r\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\r\n    <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\r\n    <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\r\n    <link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Inter:wght@400;800&display=swap\">\r\n    <link rel=\"stylesheet\" href=\"./main.css\">\r\n    <link rel=\"icon\" type=\"image/svg+xml\" href=\"/logo.svg\">\r\n  </head>\r\n  <body>\r\n  <header>\r\n    <span>\r\n      Test presentation\r\n    </span>\r\n    <nav>\r\n      <button id=\"previous-slide\"><</button>\r\n      <span id=\"slide-count\"></span>\r\n      <button id=\"next-slide\">></button>\r\n      <button id=\"previous-deck\"><<</button>\r\n      <span id=\"deck-count\"></span>\r\n      <button id=\"next-deck\">>></button>\r\n    </nav>\r\n  </header>\r\n\t<main><section><h1>Title</h1></section><section><h2>Subtitle</h2></section><section><ul><li>Bullet 1</li><li><a href=\"http://google.com\" target=\"_blank\">Bullet 2</a></li></ul></section><section><img src=\"http://fotos.com/1\" alt=\"Some image\"/></section><section><quote>Smart word</quote></section><footer><h1>Test presentation</h1><span>2024/10/26</span><span>Pp</span></footer></main>\n\r\n\t<script src=\"main.js\"></script>\r\n  </body>\r\n</html>\r\n\r\n"
           ((capture-stdout (ps/main "parse" "Test presentation" "./test/presentation.md")) 1)))
(end-suite)
