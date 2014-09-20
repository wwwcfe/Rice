//
//  ActionViewController.m
//  Viewer
//
//  Created by wwwcfe on 2014/09/20.
//  Copyright (c) 2014年 wwwcfe. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ActionViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *countButton;

@property (strong, nonatomic) NSArray *bookmarks;

@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 追加。セルの高さを自動で良い感じにする。
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80.f;

    BOOL found = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            
            // URL だけ取り出す
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                __weak typeof(self) wself = self;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *item, NSError *error) {
                    [wself loadURL:item];
                }];
                
                found = YES;
                break;
            }
        }
        
        if (found) {
            // 最初の一個しかみないので break する
            break;
        }
    }
}

- (void)loadURL:(NSURL *)url {
    NSString *escaped = [url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *endpoint = [NSString stringWithFormat:@"http://b.hatena.ne.jp/entry/jsonlite/?url=%@", escaped];
    __weak typeof(self) wself = self;
    NSLog(@"%@", endpoint);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"%@", d);
        [wself updateViewWithDictionary:d];
    }];
}

- (void)updateViewWithDictionary:(NSDictionary *)d {
    NSNumber *count = d[@"count"];
    NSArray *bookmarks = d[@"bookmarks"];
    self.countButton.title = [NSString stringWithFormat:@"%@", count];
    self.bookmarks = bookmarks;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bookmarks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    NSDictionary *bookmark = self.bookmarks[indexPath.row];
    NSString *comment = bookmark[@"comment"];
    NSString *user = bookmark[@"user"];
    NSString *timestamp = bookmark[@"timestamp"];
    //NSArray *tags = bookmark[@"tags"];
    
    __weak UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    imageView.image = nil;
    [self loadImageWithUserID:user completionHandler:^(UIImage *image) {
        imageView.image = image;
    }];
    
    UILabel *userLabel = (UILabel *)[cell viewWithTag:200];
    userLabel.text = user;
    
    UILabel *timestampLabel = (UILabel *)[cell viewWithTag:300];
    timestampLabel.text = timestamp;
    
    UILabel *commentLabel = (UILabel *)[cell viewWithTag:400];
    commentLabel.text = comment;
    return cell;
}

- (void)loadImageWithUserID:(NSString *)userID completionHandler:(void(^)(UIImage *image))handler {
    static NSCache *cache = nil;
    if (!cache) {
        cache = [[NSCache alloc] init];
        cache.countLimit = 1000;
    }
    
    NSString *s = @"http://n.hatena.com/%@/profile/image.gif?type=face&size=64";
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:s, userID]];
    
    // キャッシュから取り出す
    UIImage *cachedImage = [cache objectForKey:url.absoluteString];
    if (cachedImage) {
        if (handler) handler(cachedImage);
        return;
    }
    
    // なれけば通信して取得
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
            if (handler) {
                handler(nil);
            }
            return;
        }
        
        [cache setObject:image forKey:url.absoluteString];
        if (handler) {
            handler(image);
        }
    }];
}

- (IBAction)done {
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

@end
