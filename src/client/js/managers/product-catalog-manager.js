export class ProductCatalogManager {
  constructor(catalogUrl = '/api/products') {
    this.catalogUrl = catalogUrl;
    this.productCatalog = [];
  }

  async loadCatalog() {
    const response = await fetch(this.catalogUrl, {
      headers: {
        Accept: 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`Failed to load product catalog: ${response.status}`);
    }

    const catalogData = await response.json();
    this.productCatalog = Array.isArray(catalogData) ? catalogData : [];
    return this.productCatalog;
  }
}
