//
//  IAPHelper.m
//  PhotoBlend
//
//  Created by Mahmudul Hasan on 5/29/17.
//  Copyright © 2017 Mahmudul Hasan. All rights reserved.
//

#import "IAPHelper.h"

@implementation IAPHelper

+ (IAPHelper *)sharedIAP {
    static IAPHelper *sharedMyIAP = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyIAP = [[self alloc] init];
    });
    return sharedMyIAP;
}

- (id)init {
    if (self = [super init]) {
        productsPrice = [[NSMutableDictionary alloc] init];
        productsPurchased = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isInternetAvailable {
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        return NO;
    }
    return YES;
}

- (void)initProductIdentifiers:(NSArray *)idArray {
    
    [[ERProgressHud sharedInstance] show];
    productIdentifiers = [NSSet setWithArray:idArray];
}

- (void)fetchAvailableProducts {
   // NSSet *productIdentifiers = [NSSet setWithObjects:IAP_PRODUCT_ID,nil];
    productsRequest = [[SKProductsRequest alloc]
                       initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

- (void)purchaseMyProduct:(SKProduct*)product{
    
    if ([self canMakePurchases]) {
        currentProductID = product.productIdentifier;
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else{
        [[ERProgressHud sharedInstance] hide];
        NSLog(@"Purchases are disabled in your device");
    }
}
-(IBAction)purchase:(id)sender {
    
    [[ERProgressHud sharedInstance] show];
    [self purchaseMyProduct:[_validProducts objectAtIndex:0]];
}

-(IBAction)restorePurchase:(id)sender {
    
    [[ERProgressHud sharedInstance] show];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (NSString *)getLocalePrice:(SKProduct *)product {
    if (product) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        
        return [formatter stringFromNumber:product.price];
    }
    return @"";
}

#pragma mark StoreKit Delegate

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing");
                break;
            case SKPaymentTransactionStatePurchased:
                if ([transaction.payment.productIdentifier isEqualToString:currentProductID]) {
                    
                    NSLog(@"Purchased ");

                    if (self.delegate && [self.delegate respondsToSelector:@selector(purchaaseCompleteWithStatus:)]) {
                        [self.delegate purchaaseCompleteWithStatus:PURCHASE_STATUS_COMPLETED];
                    }
                    [APPManager showAlertWithTitle:@"Success" andMessage:@"Purchase is completed succesfully"];
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                NSLog(@"Restored ");
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(purchaaseCompleteWithStatus:)]) {
                    [self.delegate purchaaseCompleteWithStatus:PURCHASE_STATUS_RESTORED];
                }
                [APPManager showAlertWithTitle:@"Success" andMessage:@"Purchase is restored succesfully"];

                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                NSLog(@"Purchase failed ");
                if (self.delegate && [self.delegate respondsToSelector:@selector(purchaaseCompleteWithStatus:)]) {
                    [self.delegate purchaaseCompleteWithStatus:PURCHASE_STATUS_FAILED];
                }
                [APPManager showAlertWithTitle:@"Failed" andMessage:@"Sorry! Purchase is failed, Please try again later."];
                break;
                
            case SKPaymentTransactionStateDeferred:
                NSLog(@"Purchase Defereed");
                break;
                
            default:
                break;
        }
        [[ERProgressHud sharedInstance] hide];
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    SKProduct *validProduct = nil;
    int count = (int)[response.products count];
    if (count>0) {
        _validProducts = response.products;
        for (validProduct in _validProducts) {
            for (NSString* productIden in productIdentifiers) {
                if ([validProduct.productIdentifier isEqualToString:productIden]){
                    NSString *productTitle = [NSString stringWithFormat:
                                              @"Product Title: %@",validProduct.localizedTitle];
                    NSString *productDes = [NSString stringWithFormat:
                                            @"Product Desc: %@",validProduct.localizedDescription];
                    NSString *productPrice = [self getLocalePrice:validProduct];
                    NSLog(@"Product Info: %@, %@, %@", productTitle, productDes, productPrice);
                    [productsPrice setValue:productPrice forKey:productIden];
                }
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(availableProducts)]) {
            [self.delegate availableProducts];
        }

    } else {
        [APPManager showAlertWithTitle:@"Not Available" andMessage:@"No products to purchase"];
        NSLog(@"No products to purchase""");
    }
    [[ERProgressHud sharedInstance] hide];
}

@end
