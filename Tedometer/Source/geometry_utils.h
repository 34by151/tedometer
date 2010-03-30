/*
 *  geometry_utils.h
 *  Ted-O-Meter
 *
 *  Created by Nathan on 2/8/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import <QuartzCore/QuartzCore.h>

double magnitude( CGPoint p );
double distanceFromCenterToEdgeOfRectAtAngle( CGSize size, double angle );
CGPoint cartesianToPolar( CGPoint p );
CGPoint polarToCartesian( CGPoint p );
double distanceBetweenPoints( CGPoint p1, CGPoint p2 );
double angleBetweenPoints( CGPoint origin, CGPoint p1, CGPoint p2 );
double radiansToDegrees( double rad );