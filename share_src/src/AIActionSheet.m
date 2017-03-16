//
//  AIActionSheet.m
//  CommonProject
//
//  Created by wuyoujian on 16/8/12.
//  Copyright © 2016年 wuyoujian. All rights reserved.
//

#import "AIActionSheet.h"

static NSString *const kAIActionSheetCellIdentifier = @"AIActionSheetCellIdentifier";
static NSInteger const kAIActionSheetCellWidth = 65;
static NSInteger const kAIActionSheetCellHeight = kAIActionSheetCellWidth + 20;

@implementation AISheetItem
@end

@interface inline_AIActionSheetCell : UICollectionViewCell

- (void)setSheetAction:( AISheetItem *)action;

@property(nonatomic,strong) UIImageView         *iconImageView;
@property(nonatomic,strong) UILabel             *titleLabel;
@end


@implementation inline_AIActionSheetCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        //
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kAIActionSheetCellWidth, kAIActionSheetCellWidth)];
        _iconImageView.userInteractionEnabled = YES;
        _iconImageView.clipsToBounds = YES;
        [self.contentView addSubview:_iconImageView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kAIActionSheetCellHeight - 15, self.bounds.size.width, 15)];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_titleLabel setFont:[UIFont systemFontOfSize:13]];
        [self.contentView addSubview:_titleLabel];
    }
    
    return self;
}

- (void)setSheetAction:( AISheetItem *)item {
    
    if (item.icon && [item.icon length] > 0) {
        [_iconImageView setImage:[UIImage imageNamed:item.icon]];
    }
    
    if (item.iconPath && [item.iconPath length] > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:item.iconPath];
        [_iconImageView setImage:image];
    }
    
    [_titleLabel setText:item.title];
}

@end


@interface AIActionSheet ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *mainMenuView;
@property (nonatomic, strong) UIView *markView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *menuBGView;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, assign) NSInteger     contentHeight;
@property (nonatomic, assign) NSInteger     menuBGHeight;
@property (nonatomic, assign) NSInteger     lineSpacing;

@property (nonatomic, strong) NSMutableArray *menuDatas;
@property (nonatomic, assign) NSInteger cancelButtonIndex;
@property (nonatomic, weak) id < AIActionSheetDelegate > delegate;
@property (nonatomic, copy) AIActionSheetBlock block;
@end

@implementation AIActionSheet

- (instancetype)initInParentView:(UIView*)parentView block:( AIActionSheetBlock )block {
    self.block = block;
    return [self initInParentView:parentView delegate:nil];
}


- (instancetype)initInParentView:(UIView*)parentView delegate:(id < AIActionSheetDelegate >)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // Initialization code.
        self.parentView = parentView;
        self.delegate = delegate;
        if (delegate) {
            self.block = nil;
        }
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
        
        self.markView = [[UIView alloc] initWithFrame:CGRectZero];
        _markView.backgroundColor = [UIColor clearColor];
        [self addSubview:_markView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [_markView addGestureRecognizer:tap];
        
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.clipsToBounds = YES;
        [self addSubview:_contentView];
        
        self.menuBGView = [[UIView alloc] initWithFrame:CGRectZero];
        [_menuBGView.layer setCornerRadius:8.0];
        _menuBGView.backgroundColor = [UIColor whiteColor];
        [_contentView addSubview:_menuBGView];
        
        //初始化
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        flowLayout.minimumInteritemSpacing = 0 ;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.headerReferenceSize = CGSizeZero;
        flowLayout.footerReferenceSize = CGSizeZero;
        
        self.mainMenuView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        // 注册
        [_mainMenuView registerClass:[inline_AIActionSheetCell class] forCellWithReuseIdentifier:kAIActionSheetCellIdentifier];
        _mainMenuView.backgroundColor = [UIColor clearColor];
        _mainMenuView.showsVerticalScrollIndicator = NO;
        _mainMenuView.showsHorizontalScrollIndicator = NO;
        _mainMenuView.delegate = self;
        _mainMenuView.dataSource = self;
        [_menuBGView addSubview:_mainMenuView];
    
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_cancelButton.layer setCornerRadius:8.0];
        _cancelButton.backgroundColor = [UIColor whiteColor];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:_cancelButton];
        
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initInParentView:nil delegate:nil];
}

- (void)cancelAction:(UIButton*)sender {
    [self dismiss];
    if (_delegate && [_delegate respondsToSelector:@selector(didSelectedActionSheet:buttonIndex:)]) {
        [_delegate didSelectedActionSheet:self buttonIndex:_cancelButtonIndex];
    }
    
    if (_block) {
        _block(self,_cancelButtonIndex);
    }
}

- (void)clearAllItems {
    if (_menuDatas) {
        [_menuDatas removeAllObjects];
    }
}

- (void)addActionItem:( AISheetItem *)item {
    if (_menuDatas == nil) {
        self.menuDatas = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    //
    [_menuDatas addObject:item];
}

- (void)calculateLayoutWillShowing {
    
    [self setFrame:_parentView.bounds];
    [_markView setFrame:self.bounds];
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    
    NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;
    NSInteger columCount = 3;
    if (screenWidth >= 414) {
        // 6+ 4列
        columCount = 4;
    }
    
    self.cancelButtonIndex = [_menuDatas count];
    _lineSpacing = (screenWidth - 20 - columCount * kAIActionSheetCellWidth)/(columCount + 1);
    
    NSInteger rowCount = [_menuDatas count] % columCount == 0? [_menuDatas count] / columCount : [_menuDatas count] / columCount + 1;

    if ([_menuDatas count] > 6) {
        rowCount = 2;
    }

    _menuBGHeight = (rowCount + 1) * _lineSpacing + rowCount * kAIActionSheetCellHeight;
    
    _contentHeight = _menuBGHeight + 10 + 44 + 10;
    [_contentView setFrame:CGRectMake(10, _parentView.frame.size.height + _contentHeight, _parentView.frame.size.width-20, _contentHeight)];
    
    [_menuBGView setFrame:CGRectMake(0, 0, _contentView.frame.size.width,_menuBGHeight)];
    [_mainMenuView setFrame:CGRectMake(_lineSpacing, _lineSpacing, _contentView.frame.size.width - 2*_lineSpacing, (rowCount*kAIActionSheetCellHeight + (rowCount-1)*_lineSpacing))];
    [_mainMenuView reloadData];
    
    [_cancelButton setFrame:CGRectMake(0, _menuBGHeight + 10 , _contentView.frame.size.width, 44)];
}

- (void)show {
    
    [_parentView addSubview:self];
    [self calculateLayoutWillShowing];
    
    __weak typeof(self)wSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        [wSelf.contentView setFrame:CGRectMake(10, wSelf.parentView.frame.size.height - _contentHeight, wSelf.parentView.frame.size.width-20, wSelf.contentHeight)];
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    } completion:^(BOOL finished) {
    }];
}

- (void)tapAction:(UITapGestureRecognizer*)sender {
    [self removeGestureRecognizer:sender];
    [self dismiss];
}

- (void)dismiss {
    
    __weak typeof(self)wSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        
        [self setFrame:CGRectMake(0, 0, wSelf.parentView.frame.size.width, wSelf.parentView.frame.size.height)];
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
        [wSelf.contentView setFrame:CGRectMake(10, wSelf.parentView.frame.size.height + wSelf.contentHeight, wSelf.parentView.frame.size.width-20, wSelf.contentHeight)];
        
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - collectionView delegate
//设置分区
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

//每个分区上的元素个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_menuDatas count];
}

//设置元素内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    inline_AIActionSheetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAIActionSheetCellIdentifier forIndexPath:indexPath];
    
    [cell sizeToFit];
    [cell setSheetAction:[_menuDatas objectAtIndex:indexPath.row]];
    
    return cell;
}

//
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets top = {0,0,0,0};
    return top;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return _lineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return _lineSpacing;
}

//设置元素大小
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(kAIActionSheetCellWidth,kAIActionSheetCellHeight);
}


//点击元素触发事件
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self dismiss];
    if (_delegate && [_delegate respondsToSelector:@selector(didSelectedActionSheet:buttonIndex:)]) {
        [_delegate didSelectedActionSheet:self buttonIndex:indexPath.row];
        
    }
    
    if (_block) {
        _block(self,indexPath.row);
    }
}



@end
