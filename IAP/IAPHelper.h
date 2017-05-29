//
//  IAPHelper.h
//  PhotoBlend
//
//  Created by Mahmudul Hasan on 5/29/17.
//  Copyright © 2017 Mahmudul Hasan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "Reachability.h"
#import "ERProgressHud.h"
#import "APPManager.h"

@protocol IAPHelperDelegate <NSObject>

@required
//Required Deleagte Method

@optional
//Optional Deleagte Method

- (void)purchaaseCompleteWithStatus: (NSInteger)status;
- (void)availableProducts;

@end

@interface IAPHelper : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver> {
    
    SKProductsRequest *productsRequest;
    NSSet *productIdentifiers;
    NSMutableDictionary *productsPrice;
    NSString *currentProductID;
    NSMutableArray *productsPurchased;
}

@property (nonatomic, weak) id<IAPHelperDelegate> delegate;
@property (nonatomic, strong) NSArray *validProducts;


+ (IAPHelper *)sharedIAP;

- (BOOL)isInternetAvailable;
- (void)initProductIdentifiers:(NSArray *)idArray;
- (void)fetchAvailableProducts;
- (BOOL)canMakePurchases;
- (void)purchaseMyProduct:(SKProduct*)product;
- (IBAction)purchase:(id)sender;

typedef enum {
    PURCHASE_STATUS_COMPLETED = 1,
    PURCHASE_STATUS_RESTORED,
    PURCHASE_STATUS_FAILED,
    PURCHASE_STATUS_CANCELLED
    
}PURCHASE_STATUS;

@end
