#!/usr/bin/env python3
import re

PEARL_RE=re.compile(r'(?P<study>[EM])(?P<identifier>\d\d\d)(?P<baby>B?\d?)(?P<time>W\d+|T\d+|M\d+|Birth)(?P<replica>\d*)')