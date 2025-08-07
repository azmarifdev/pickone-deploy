/**
 * Utility functions for handling image URLs
 */

/**
 * Convert relative image URL to absolute URL
 * Handles both relative and absolute URLs
 */
export const getImageUrl = (imageUrl: string | undefined | null): string => {
    // Return empty string for null/undefined
    if (!imageUrl || imageUrl.trim() === '') {
        return '';
    }

    // If already absolute URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return imageUrl;
    }

    // Get base URL from environment
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || '';

    // Clean up URL paths
    const cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
    const cleanImageUrl = imageUrl.startsWith('/') ? imageUrl : `/${imageUrl}`;

    return `${cleanBaseUrl}${cleanImageUrl}`;
};

/**
 * Get image URL with fallback
 */
export const getImageUrlWithFallback = (
    imageUrl: string | undefined | null,
    fallback: string = '/placeholder.jpg',
): string => {
    const processedUrl = getImageUrl(imageUrl);
    return processedUrl || fallback;
};
