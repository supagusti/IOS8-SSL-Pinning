//
//  ViewController.m
//  SSL-Pinning
//
//  Created by Ing. Thomas Mitschke on 11.10.14.
//  Copyright (c) 2014 Ing. Thomas Mitschke. All rights reserved.
//

// ------------------- IMPORTANT ---------------------
//
// DONT FORGET TO IMPORT A CERTIFICATE OF TYPE "DER" INTO THE PROJECT !!!!!
// Edit: If the certificate doesn't exist, it will be downloaded from the web.



#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"View Did Load...");
    
    
    //Download certificate
    [self printMessage:@"----------------------------------------------\nCheck for new Certificate\n----------------------------------------------"];
    //Create certs folder
    NSError *createDirError;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libDirectory = [paths objectAtIndex:0]; // Get Library folder
    //NSLog(@"found folders: %@",paths);
    NSString *dataPath = [libDirectory stringByAppendingPathComponent:@"/certs"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
    {
        //Create Folder
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&createDirError];
    }
    
    //Download the certificate (synchonous)
    NSError *downloadError;
    NSString *stringURL = @"http://www.mitschke.tk/cert/star.mitschke.tk.der.cer";
    NSURL  *url = [NSURL URLWithString:stringURL];
    NSData *urlData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&downloadError];
    if (downloadError)
    {
       [self printMessage:@"Error in certificate data download!"];
        NSLog(@"%@", [downloadError localizedDescription]);

    }
    else
    {
       [self printMessage:@"Certificate data has been downloaded successfully."];
    }
    
    
    if ( urlData )
    {
        NSLog(@"Certificate Download finished!");
        NSString  *cerPath = [NSString stringWithFormat:@"%@/certs/%@", libDirectory,@"star.mitschke.tk.der.cer"];
        NSData *localCert = [NSData dataWithContentsOfFile:cerPath];
        
        if ([urlData isEqualToData:localCert])
        {
            [self printMessage:@"Certs are equal - do not save"];
        }
        else
        {
            [self printMessage:@"Certs are NOT equal - saving..."];
            [urlData writeToFile:cerPath atomically:YES];
        }
    }
    
    [self printMessage:@"----------------------------------------------\nCheck for new Certificate finished!\n----------------------------------------------"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)MakeHTTPRequestTapped
{
    NSLog(@"MakeHTTPRequestTapped...");
    self.textOutput.text=@"";
    NSURL *httpsURL = [NSURL URLWithString:@"https://www.mitschke.tk/ssltest.php"];
    NSURLRequest *request = [NSURLRequest requestWithURL:httpsURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:15.0f];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [self.connection start];
    [self printMessage:@"Making pinned request"];
}


- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"willSendRequestForAuthenticationChallenge...");
    
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
    //NSLog(@"remoteCertData = %@",remoteCertificateData);
    NSData *localCertificateData = [self localCertificate];
    //NSLog(@"localCertificateData = %@",localCertificateData);
    
    CFStringRef certSummary = SecCertificateCopySubjectSummary(certificate);
    NSString* summaryString = [[NSString alloc]initWithString:(__bridge NSString *)certSummary];
    NSLog(@"remote CertData \n---------START ----------\n%@\n-----------END--------------\n",summaryString);
    
    
    
    if ([remoteCertificateData isEqualToData:localCertificateData]) {
        
       [self printMessage:@"The server's certificate is the valid certificate. Allowing the request."];
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    }
    else {
        [self printMessage:@"The server's certificate does not match. Canceling the request."];
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (self.responseData == nil) {
        self.responseData = [NSMutableData dataWithData:data];
    }
    else {
        [self.responseData appendData:data];
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    [self printMessage:[NSString stringWithFormat:@"\nWebserver responded:%@",response]];
    self.responseData = nil;
}


- (NSData *)localCertificate
{
    //Downloaded Certificate:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libDirectory = [paths objectAtIndex:0]; // Get Library folder
    NSString  *cerPath = [NSString stringWithFormat:@"%@/certs/%@", libDirectory,@"star.mitschke.tk.der.cer"];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:cerPath];
    NSData *localCert = nil;
    if (fileExists)
    {
       [self printMessage:@"Using local (downloaded) certificate data "];
        localCert = [NSData dataWithContentsOfFile:cerPath];
    }
    else
    {
        [self printMessage:@"Local (downloaded) certificate data is empty, using bundle data instead!"];
        //Bundle stored Certificate
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"star.mitschke.tk.der" ofType:@"cer"];
        localCert = [NSData dataWithContentsOfFile:cerPath];
        //NSLog(@"CertPath= %@ CertData=%@",cerPath,localCert);
    }

    
    //Do some cert info....
    CFDataRef CertCFDataRef = (__bridge CFDataRef)localCert;
    SecCertificateRef thisCert = SecCertificateCreateWithData(nil,CertCFDataRef);
    
    CFStringRef certSummary = SecCertificateCopySubjectSummary(thisCert);
    NSString* summaryString = [[NSString alloc]initWithString:(__bridge NSString *)certSummary];
    NSLog(@"local CertData \n---------START ----------\n%@\n-----------END--------------\n",summaryString);
    
    
    
    return localCert;
  
}




- (void)printMessage:(NSString *)message
{
    NSString *existingMessage = self.textOutput.text;
    self.textOutput.text = [existingMessage stringByAppendingFormat:@"\n%@", message];
    NSLog(@"%@ \n",message);
}


- (BOOL)isSSLPinning
{
    NSString *envValue = [[[NSProcessInfo processInfo] environment] objectForKey:@"SSL_PINNING"];
    return [envValue boolValue];
}


@end
