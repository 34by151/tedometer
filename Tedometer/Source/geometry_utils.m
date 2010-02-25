/*
 *  geometry_utils.cpp
 *  Ted-O-Meter
 *
 *  Created by Nathan on 2/8/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "geometry_utils.h"


double magnitude( CGPoint p ) {
	return distanceBetweenPoints( p, CGPointMake( 0, 0 ) );
}


/** 
 * Converts (x,y) to (magnitude, angle);
 */
CGPoint cartesianToPolar( CGPoint p ) {
	double angle = atan2( p.y, p.x );
	return CGPointMake( magnitude( p ), angle );
}

/**
 * Converts (magnitude, angle) to (x,y)
 */
CGPoint polarToCartesian( CGPoint p ) {
	return CGPointMake( p.x * cos( p.y ), p.x * sin( p.y ) );
}

double distanceFromCenterToEdgeOfRectAtAngle( CGSize size, double angle ) {
	
	// from http://stackoverflow.com/questions/1343346/calculate-a-vector-from-the-center-of-a-square-to-edge-based-on-radius/1343531#1343531
	
	double magnitude;
	
	double abs_cos_angle= fabs(cos(angle));
	double abs_sin_angle= fabs(sin(angle));
	if( size.width/2.0 * abs_sin_angle <= size.height/2.0 * abs_cos_angle)
		magnitude = size.width/2.0/abs_cos_angle;
	else
		magnitude = size.height/2.0/abs_sin_angle;
	
	return magnitude;
}

double distanceBetweenPoints( CGPoint p1, CGPoint p2 ) {
	double distance = sqrt( (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y) );
	return distance;
}

double angleBetweenPoints( CGPoint origin, CGPoint p1, CGPoint p2 ) {
	
	double angle;
	CGPoint v1 = CGPointMake( p1.x - origin.x, p1.y - origin.y );
	CGPoint v2 = CGPointMake( p2.x - origin.x, p2.y - origin.y );
	double dotProd = v1.x * v2.x + v1.y * v2.y;
	angle = acos( dotProd / (magnitude( v1 ) * magnitude( v2 )) ); 
	
	return angle;
}

double radiansToDegrees( double radians ) {
	return radians / M_PI * 180.0;
}
