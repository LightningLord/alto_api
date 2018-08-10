#!/bin/bash

# How to run this script:
#
# 0. Make sure Python and html5lib (https://pypi.python.org/pypi/html5lib) are installed. This script will not work without them. (On OSX with homebrew (https://brew.sh) this should be `brew install python; pip install html5lib`).
# 1. Run your server
# 2. Set $HOST and $PORT below accordingly
# 3. %> ./test.sh

HOST=localhost                  # name of HOST at which your server is running
PORT=3000                       # PORT on which your server is listening

OUT=out.txt                     # output file this script will write to
EXP=expected_out.txt            # file that contains expected contents of the output file after this script is run

formatHTML() {
    read input
    echo $input | python -c "import html5lib as h5; import sys; sys.stdout.write(h5.serialize(h5.parse(sys.stdin.read()), quote_attr_values='always'))"
}

rm -f $OUT
touch $OUT

echo >> $OUT
echo '=== Test create, fetch, update ===' >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/alex" -d '{ "url": "http://alex.com" }'
curl -XGET "http://$HOST:$PORT/names/alex" | formatHTML >> $OUT
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/alex" -d '{ "url": "http://alex.org" }'
curl -XGET "http://$HOST:$PORT/names/alex" | formatHTML >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -XGET "http://$HOST:$PORT/names/alex" -s -o /dev/null -w 'HTTP status code: %{http_code}\n' >> $OUT

echo >> $OUT
echo '=== Test simple annotation ===' >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/alex" -d '{ "url": "http://alex.com" }'
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d 'my name is alex' | formatHTML >> $OUT
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d 'my name is todd' | formatHTML >> $OUT

echo >> $OUT
echo '=== Test annotation of multiple names ===' >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/alex" -d '{ "url": "http://alex.com" }'
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/bo" -d '{ "url": "http://bo.com" }'
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/casey" -d '{ "url": "http://casey.com" }'
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d 'alex, bo, and casey went to the park.' | formatHTML >> $OUT
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d 'alex alexander alexandria alexbocasey' | formatHTML >> $OUT

echo >> $OUT
echo '=== Test HTML correctness ===' >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/alex" -d '{ "url": "http://alex.com" }'
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d '<div data-alex="alex">alex</div>' | formatHTML >> $OUT
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d '<a href="http://foo.com">alex is already linked</a> but alex is not' | formatHTML >> $OUT
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d "<div><p>this is paragraph 1 about alex.</p><p>alex's paragraph number 2.</p><p>and some closing remarks about alex</p></div>" | formatHTML >> $OUT

echo >> $OUT
echo '=== Test additional annotations ===' >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/alex" -d '{ "url": "http://alex.com" }'
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/bo" -d '{ "url": "http://bo.com" }'
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/casey" -d '{ "url": "http://casey.com" }'
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d '<div data-alex="alex">alex</div>' | formatHTML >> $OUT
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d "<div><p>this is paragraph 1 about alex.</p><p>alex's paragraph number 2.</p><p>and some closing remarks about alex</p></div>" | formatHTML >> $OUT
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d "<div><ul><li>alex</li><li>bo</li><li>bob</li><li>casey</li></ul></div><div><p>this is paragraph 1 about alex.</p><p>alex's paragraph number 2.</p><p>and some closing remarks about alex</p></div>" | formatHTML >> $OUT

echo >> $OUT
echo '=== Tricky case ===' >> $OUT
curl -XDELETE "http://$HOST:$PORT/names"
curl -H 'Content-Type:application/json' -XPUT "http://$HOST:$PORT/names/name" -d '{ "url": "https://name.com" }'
curl -H 'Content-Type:text/plain' -XPOST "http://$HOST:$PORT/annotate" -d "<div class='<div class=\"name\">name</a>'>name</div>" | formatHTML >> $OUT

DIFF=$(diff --unified --ignore-case $EXP $OUT)
echo ''
if [ "" == "$DIFF" ]; then
    echo '####################################'
    echo '#          RESULT: success         #'
    echo '####################################'
else
    echo '####################################'
    echo '#           TEST ERRORS:           #'
    echo '####################################'
    diff --unified --ignore-case $EXP $OUT
fi