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
//



#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"View Did Load...");

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
    [self printMessage:response];
    self.responseData = nil;
}


- (NSData *)localCertificate
{
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"star.mitschke.tk.der" ofType:@"cer"];
    NSData *localCert = [NSData dataWithContentsOfFile:cerPath];
    //NSLog(@"CertPath= %@ CertData=%@",cerPath,localCert);
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
