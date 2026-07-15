import { ProductCatalogManager } from './managers/product-catalog-manager.js';
import { ProductListRenderer } from './renderers/product-list-renderer.js';

const productCatalogManager = new ProductCatalogManager();
const productListRenderer = new ProductListRenderer('#product-list');

const initializeStorefront = async () => {
  try {
    const productCatalog = await productCatalogManager.loadCatalog();
    productListRenderer.renderProducts(productCatalog);
  } catch (error) {
    console.error('Unable to initialize product catalog.', error);
    productListRenderer.renderError('Products are temporarily unavailable. Please try again later.');
  }
};

document.addEventListener('DOMContentLoaded', () => {
  initializeStorefront();
});
