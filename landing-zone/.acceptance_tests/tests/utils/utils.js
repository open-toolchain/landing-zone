const { assert, util } = require("chai"); // Chai for automated testing
require("dotenv").config(); // Env to get sensitive variables

/**
 * Utils for running tests against terraform plan
 * @param {string} scriptFilePath Relative file path for the script relative to script where constructor is initialized
 * @param {string} filePath Relative file path for directory to be checked from where constructor is initialized
 */
const utils = function (scriptFilePath, filePath) {
  /**
   * Get Plan JSON from the file path where this utils object is initialized.
   * @param exec Child process exec function, passed to ensure unit tests
   * @returns The planned values from a terraform plan
   */
  this.getPlanJson = async function (exec) {
    try {
      // Exec bash and await value
      const bash = await exec(
        `sh ${scriptFilePath} ${process.env.API_KEY} ${filePath}`
      );
      // Parse stdout to JSON
      let tfplan = JSON.parse(bash.stdout).planned_values;
      // Return data
      return tfplan;
    } catch (err) {
      throw new Error(err);
    }
  };

  /**
   * Create a set of unit tests for a single resource in a plan this is called by `testModule`
   * @param {string} resourceName The plain text name of the resource to test
   * @param {Object} moduleData Terraform plan data
   * @param {string} address Address of the resource within the module
   * @param {Object} resourceData An object containing the resource and expected values including name and type
   * @param {Object} resourceValues An object containing values found in the resource object within the plan
   * @returns A set of tests to test the values within a resource
   */

  this.testResource = function (resourceName, moduleData, address, planValues) {
    // Return dynamic unit tests
    return describe(`${resourceName}`, () => {
      let resourceData = false; // initialize as false to check
      // For each resource if the address matches, set resource data to the resource
      moduleData.resources.forEach((resource) => {
        if (resource.address == `${moduleData.address}.${address}`) {
          resourceData = resource;
        }
      });
      // Ensure module contains resource
      it(`Module ${moduleData.address} should contain resource ${address}`, () => {
        assert.isNotFalse(
          resourceData,
          `Expected ${moduleData.address} contain the ${resourceName} resource.`
        );
      });
      // If module does contain resource
      if (resourceData !== false) {
        let planValueKeys = Object.keys(planValues);
        // Check values for expected values
        planValueKeys.forEach((key) => {
          it(`${resourceName} should have the correct ${key} value`, () => {
            if (planValues[key] instanceof Function) {
              // If the plan value contains a function, run the actual data against that function
              // Check to ensure the results are true
              let results = planValues[key](resourceData.values[key]);
              assert.isTrue(
                results.expectedData,
                `Expected ${address} resource ${key} value ${results.appendMessage}`
              );
            } else {
              // Otherwise, check to make sure the values are equal
              assert.deepEqual(
                resourceData.values[key],
                planValues[key],
                `Expected ${address} to have correct value for ${key}.`
              );
            }
          });
        });
      }
    });
  };

  /**
   * Test a module and all of it's components
   * @param {string} moduleName Plain text name for the module
   * @param {string} address Module address. Should be relative to the parent module
   * @param {Object} tfPlan Object containing terraform plan data
   * @param {Array<Object>} resources Array of resources with name, address, and values
   * @returns Tests for each resource in the resources array
   */

  this.testModule = function (moduleName, address, tfPlan, resources) {
    // Return descrive for module
    return describe(`Module ${moduleName}`, () => {
      // Get child module from root module
      let moduleData = tfPlan.root_module.child_modules[0];
      // Initialize Module found
      let moduleFound = true;
      // If the module data address does not match module address
      if (moduleData.address != address) {
        // Set module found to false
        moduleFound = false;
        // Reference for array of root module children
        childModuleArray = moduleData.child_modules;
        // Reference to expected child module address
        address = `${moduleData.address}.${address}`;
        // While there are still unchecked children of the module and the module has not been found
        while (childModuleArray.length > 0 && !moduleFound) {
          // If the module is found, set moduleData to the first element of childModuleArray
          if (childModuleArray[0].address == address) {
            moduleFound = true;
            moduleData = childModuleArray[0];
          } else {
            // Otherwise remove first element
            childModuleArray.shift();
          }
        }
      }
      // Test assertion that the module should be contained in the plan
      it(`Plan should contain the module ${address}`, () => {
        assert.isTrue(
          moduleFound,
          `The module ${address} should exist in the terraform plan.`
        );
      });
      // If the module is found, return tests for each resource
      if (moduleFound) {
        resources.forEach((resource) => {
          this.testResource(
            resource.name,
            moduleData,
            resource.address,
            resource.values
          );
        });
      }
    });
  };
};

module.exports = utils;
