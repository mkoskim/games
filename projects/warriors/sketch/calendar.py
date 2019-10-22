#!/usr/bin/env python3
# -*- coding: utf-8 -*-
###############################################################################
#
# "Calendar"
#
###############################################################################

import sys
import datetime

def deg2time(deg):
    #deg = (deg + 2*15) % 360
    #print(deg * 24 / 360.0)
    return datetime.time(deg * 24 / 360, (deg % 15) * 60 / 15)
    
def info(deg, year = 2019):
    yday = (deg * 365 / 360)
    date1 = datetime.date(year, 12, 24) + datetime.timedelta(yday)
    date2 = datetime.date(year,  1,  1) + datetime.timedelta(yday)
    hour = deg2time(deg)
    
    print("%3d deg: [%02d:%02d] %02d / %02d" % (
        deg,
        hour.hour, hour.minute,
        date1.day, date1.month,
        #date2.day, date2.month,
    ))

info( 0)
info(15)
info(30)
info(45)
info(60)
info(75)

info( 90 +  0)
info( 90 + 15)
info( 90 + 30)
info( 90 + 45)
info( 90 + 60)
info( 90 + 75)

info(180 +  0)
info(180 + 15)
info(180 + 30)
info(180 + 45)
info(180 + 60)
info(180 + 75)

info(270 +  0)
info(270 + 15)
info(270 + 30)
info(270 + 45)
info(270 + 60)
info(270 + 75)

