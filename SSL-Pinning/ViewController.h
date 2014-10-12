//
//  ViewController.h
//  SSL-Pinning
//
//  Created by Ing. Thomas Mitschke on 11.10.14.
//  Copyright (c) 2014 Ing. Thomas Mitschke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLConnectionDataDelegate>
- (IBAction)MakeHTTPRequestTapped;
@property (weak, nonatomic) IBOutlet UITextView *textOutput;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *responseData;



@end

