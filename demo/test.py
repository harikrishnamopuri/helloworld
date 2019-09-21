#!/usr/bin/env python
from datetime import datetime
now = datetime.now()
current_time = now.strftime("%H:%M:%S")
print "time"
print("Current Time =", current_time)
import psutil
# gives a single float value
print "cpu"
print psutil.cpu_percent()
print "memory" \
# gives an object with many fields
print psutil.virtual_memory()
# you can convert that object to a dictionary 
dict(psutil.virtual_memory()._asdict())

