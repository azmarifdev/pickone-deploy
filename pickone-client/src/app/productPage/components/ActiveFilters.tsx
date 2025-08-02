'use client';

interface PriceRange {
    min: number;
    max: number;
    label: string;
}

interface ActiveFiltersProps {
    selectedCategory: string;
    selectedPriceRange: PriceRange | null;
    minRating: number;
    searchQuery: string;
    // eslint-disable-next-line no-unused-vars
    setSelectedCategory: (category: string) => void;
    // eslint-disable-next-line no-unused-vars
    setSelectedPriceRange: (range: PriceRange | null) => void;
    // eslint-disable-next-line no-unused-vars
    setMinRating: (rating: number) => void;

    // eslint-disable-next-line no-unused-vars
    setSearchQuery: (query: string) => void;
    resetFilters: () => void;
    activeFiltersCount: number;
}

export const ActiveFilters: React.FC<ActiveFiltersProps> = ({
    selectedCategory,
    selectedPriceRange,
    minRating,
    searchQuery,
    setSelectedCategory,
    setSelectedPriceRange,
    setMinRating,
    setSearchQuery,
    resetFilters,
}) => {
    return (
        <div className="mb-6 bg-blue-50 p-3 rounded-lg border border-blue-100">
            <div className="flex flex-wrap items-center gap-2">
                <span className="text-sm font-medium text-gray-700">Active filters:</span>

                {selectedCategory !== 'All Categories' && (
                    <span className="flex items-center bg-white text-sm px-3 py-1 rounded-full border border-gray-300">
                        {selectedCategory}
                        <button
                            onClick={() => setSelectedCategory('All Categories')}
                            className="ml-1 text-gray-500 hover:text-gray-700">
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor">
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    </span>
                )}

                {selectedPriceRange && (selectedPriceRange.min > 0 || selectedPriceRange.max < Infinity) && (
                    <span className="flex items-center bg-white text-sm px-3 py-1 rounded-full border border-gray-300">
                        {selectedPriceRange.label}
                        <button
                            onClick={() =>
                                setSelectedPriceRange({
                                    label: 'All Prices',
                                    min: 0,
                                    max: Infinity,
                                })
                            }
                            className="ml-1 text-gray-500 hover:text-gray-700">
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor">
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    </span>
                )}

                {minRating > 0 && (
                    <span className="flex items-center bg-white text-sm px-3 py-1 rounded-full border border-gray-300">
                        {minRating}+ Stars
                        <button onClick={() => setMinRating(0)} className="ml-1 text-gray-500 hover:text-gray-700">
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor">
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    </span>
                )}

                {searchQuery && (
                    <span className="flex items-center bg-white text-sm px-3 py-1 rounded-full border border-gray-300">
                        {searchQuery}
                        <button onClick={() => setSearchQuery('')} className="ml-1 text-gray-500 hover:text-gray-700">
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-4 w-4"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor">
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    </span>
                )}

                <button onClick={resetFilters} className="text-xs text-blue-600 hover:underline ml-auto">
                    Clear all filters
                </button>
            </div>
        </div>
    );
};
