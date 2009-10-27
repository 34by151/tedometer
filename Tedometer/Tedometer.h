/*
 *  Ted5000.h
 *  Ted5000
 *
 *  Created by Nathan on 10/14/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */


//#define DRAW_FOR_ICON_SCREENSHOT		// turns off tick labels, leaves "Ted-O-Meter"

// Meter sizing
#define meterGap (M_PI * 2/3)
#define radOffset (M_PI + (M_PI - meterGap)/2.0)
#define meterSpan (2*M_PI - meterGap)
#define touchThresholdAngle (M_PI / 10)
#define touchThresholdRadius 10
#define minRadiansPerTick (M_PI / 10)
#define maxRadiansPerTick (M_PI / 5)

