/**
 * Utility functions for handling image URLs in Admin Panel
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
    let cleanImageUrl = imageUrl.startsWith('/') ? imageUrl : `/${imageUrl}`;

    // 🔧 FIX: Handle legacy wrong URLs with double /tmp/
    // Replace "server-tmp/tmp/" with "server-tmp/" to fix old database records
    cleanImageUrl = cleanImageUrl.replace('/server-tmp/tmp/', '/server-tmp/');

    // 🔧 FIX: Ensure proper nginx route for file serving
    if (cleanImageUrl.startsWith('/tmp/') && !cleanImageUrl.startsWith('/server-tmp/')) {
        cleanImageUrl = cleanImageUrl.replace('/tmp/', '/server-tmp/');
    }

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
