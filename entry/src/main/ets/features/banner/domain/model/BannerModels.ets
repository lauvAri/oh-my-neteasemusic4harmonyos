export interface Banner {
  targetId: number;
  imageUrl: string;
  bigImageUrl: string;
  targetType: number;
  typeTitle: string;
  url: string;
}

export interface BannerResponse {
  code: number;
  banners: Banner[];
}
