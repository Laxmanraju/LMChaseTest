//
//  DetailViewController.h
//  LMChaseTest
//
//  Created by laxman raju on 8/31/15.
//  Copyright (c) 2015 laxman raju. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) IBOutlet UITextView *lyricsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

