(use spork/test)

(start-suite "docs")
(assert-docs "../present-star")
(end-suite)
(start-suite)
(import ../present-star/init :prefix "ps/")

(assert (= "<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <title>Test presentation</title>\n    <meta charset=\"utf-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n    <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\n    <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\n    <link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Inter:wght@400;800&display=swap\">\n    <link rel=\"stylesheet\" href=\"./main.css\">\n    <link rel=\"icon\" type=\"image/svg+xml\" href=\"/logo.svg\">\n  </head>\n  <body>\n  <header>\n    <span>\n      Test presentation\n    </span>\n  </header>\n\t\n  \t<main><section><h1>Title</h1></section><section><h2>Subtitle</h2></section><section><ul><li>Bullet 1</li><li><a href=\"http://google.com\">Bullet 2</a></li></ul></section><section><img src=\"http://fotos.com/1\" alt=\"Some image\"/></section><section><quote>Smart word</quote></section><footer><h1>Test presentation</h1><span>2024/10/26</span><span>Pp</span></footer></main>\n\t\n  </body>\n</html>\n\n"
           ((capture-stdout (ps/main "parse" "Test presentation" "./test/presentation.md")) 1)))
(end-suite)
