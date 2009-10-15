//
//  MeterView.h
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface MeterView : UIView {

	float meterValue;
	float meterMax;
	float meterMin;
}

@property (nonatomic) float meterValue;
@property (nonatomic) float meterMax;

@end
